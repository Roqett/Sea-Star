"""Discover the person's agents, so the cockpit can draw one per persona.

Two families of source are read, because "where do my agents live" has two honest
answers and reading only one of them reports an empty world.

**A harness's own store.** Osaurus (a local macOS agent harness) keeps its roster
under ``~/.osaurus/`` and can export the whole roster as one declarative document
(``osaurus config export``). Sea-Star only ever reads *that an agent exists, what
it is called and which model it is bound to* — never prompts, secrets or tool
grants.

**Agent files as a shape.** A Markdown file with a small delimited header is how
agent definitions are written by convention (``name``, ``description``,
``model``, and often ``tools``), and they live in a directory named ``agents`` —
the same directory name the JSON store uses. So the *layout* is the convention and
the *file shape* is the discriminator, which means a harness nobody has heard of
yet is read without its name appearing anywhere in this code.

Searching only the JSON store was why the cockpit could report "no roster found"
while the person had a dozen agents: it had checked one cupboard and presented the
result as the whole house. Sources are unioned, never first-match-wins, for the
same reason — a source that happens to be non-empty must not hide the others.

An entry without a name is skipped rather than given a placeholder, so the graph
never shows a phantom persona.
"""

from __future__ import annotations

import json
import os
import subprocess
from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from pathlib import Path

from .config import LOCAL_STATE_DIRNAME
from .recon import process_table

OSAURUS_HOME_DIRNAME = ".osaurus"
OSAURUS_EXPORT_FILENAMES: tuple[str, ...] = ("osaurus-config.json",)
OSAURUS_CONFIG_ENV = "SEASTAR_OSAURUS_CONFIG"


@dataclass(frozen=True, slots=True)
class AgentSpec:
    """One Osaurus agent: a name and, usually, the model it is bound to."""

    name: str
    model: str | None = None
    description: str = ""

    @property
    def provider(self) -> str | None:
        """The harness prefix of a qualified model id (``omlx/…`` -> ``omlx``)."""

        if self.model and "/" in self.model:
            return self.model.split("/", 1)[0]
        return None


def _read_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def _agent_from_entry(entry: dict, *, fallback_name: str | None = None) -> AgentSpec | None:
    """Build an :class:`AgentSpec` from one mapping, or ``None`` if it is nameless.

    Tolerant by design: Osaurus spells the model ``model`` in an export and
    ``defaultModel`` in the live store, and an entry may carry either key or none.
    The name is read the same way — ``name`` in an export, ``displayName`` in the
    default-agent file — because an orchestrator the harness knows by one key and
    the file writes by another is still a real agent, and dropping it would leave
    the cockpit short a persona.
    """

    raw_name = (
        entry.get("name")
        or entry.get("displayName")
        or entry.get("id")
        or fallback_name
    )
    if not isinstance(raw_name, str) or not raw_name.strip():
        return None
    raw_model = entry.get("model") or entry.get("defaultModel") or entry.get("default_model")
    model = str(raw_model).strip() if isinstance(raw_model, str) and raw_model.strip() else None
    raw_description = entry.get("description")
    description = raw_description.strip() if isinstance(raw_description, str) else ""
    return AgentSpec(name=raw_name.strip(), model=model, description=description)


def _agents_from_document(data: object) -> list[AgentSpec]:
    """Every agent in a declarative Osaurus document, in document order."""

    if not isinstance(data, dict):
        return []
    specs: list[AgentSpec] = []
    default = data.get("default_agent")
    if isinstance(default, dict):
        spec = _agent_from_entry(default)
        if spec is not None:
            specs.append(spec)
    listed = data.get("agents")
    if isinstance(listed, list):
        for entry in listed:
            if isinstance(entry, dict):
                spec = _agent_from_entry(entry)
                if spec is not None:
                    specs.append(spec)
    return specs


def _agents_from_home(root: Path) -> list[AgentSpec]:
    """Every agent the live ``.osaurus`` store exposes, best-effort.

    The default-agent file is read before the per-agent directory so the
    orchestrator leads, which is the order ``osaurus config export`` reports and
    the order a person reading the cockpit expects: the persona the harness
    boots into first, then the rest of the roster.
    """

    specs: list[AgentSpec] = []
    default = root / "config" / "default-agent.json"
    if default.is_file():
        data = _read_json(default)
        if isinstance(data, dict):
            spec = _agent_from_entry(data)
            if spec is not None:
                specs.append(spec)
    for filename in OSAURUS_EXPORT_FILENAMES:
        exported = root / filename
        if exported.is_file():
            specs.extend(_agents_from_document(_read_json(exported)))
    agents_dir = root / "agents"
    if agents_dir.is_dir():
        for file in sorted(agents_dir.glob("*.json")):
            data = _read_json(file)
            if isinstance(data, dict):
                spec = _agent_from_entry(data, fallback_name=file.stem)
                if spec is not None:
                    specs.append(spec)
    return specs


def read_agents(source: Path) -> tuple[AgentSpec, ...]:
    """Read agents from an Osaurus export file or a live ``.osaurus`` directory."""

    if source.is_file():
        return tuple(_agents_from_document(_read_json(source)))
    if source.is_dir():
        return tuple(_agents_from_home(source))
    return ()


#: The directory name agent definitions are written into, by convention, across
#: the tools that have them. It is a layout convention rather than a product name:
#: the JSON store above already uses it, and the Markdown form below uses it too.
AGENT_DIRNAME = "agents"

#: The fields Sea-Star needs from an agent file. A header may carry many more
#: (``tools``, ``effort``, ``mcpServers``, colours); they are deliberately not read
#: because nothing here acts on them, and reading less is what keeps this from
#: becoming a second implementation of somebody else's configuration format.
_AGENT_FIELDS: tuple[str, ...] = ("name", "description", "model")


def _agent_header(path: Path) -> dict[str, str]:
    """The simple ``key: value`` pairs in a Markdown file's delimited header.

    Returns ``{}`` when the file has no header, when the header does not open on
    the first line, or when it never closes. Only plain scalars are recognised:
    an unterminated quote or a list value simply reads as absent, because an agent
    whose header this cannot read is an agent Sea-Star declines to guess at.
    """

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return {}
    if not lines or lines[0].strip() != "---":
        return {}
    fields: dict[str, str] = {}
    for line in lines[1:]:
        if line.strip() == "---":
            return fields
        key, separator, value = line.partition(":")
        if not separator:
            continue
        name = key.strip().casefold()
        if name in _AGENT_FIELDS:
            cleaned = value.strip().strip("'\"")
            if cleaned:
                fields[name] = cleaned
    return {}


def read_agent_file(path: Path) -> AgentSpec | None:
    """One agent definition, or ``None`` when the file does not describe one.

    A ``.md`` file inside an ``agents/`` directory with a readable ``name`` is an
    agent; anything else — a README, a note, a file whose header is absent or
    unterminated — is not, and is passed over rather than half-read.
    """

    if path.suffix.casefold() != ".md":
        return None
    fields = _agent_header(path)
    name = fields.get("name")
    if not name:
        return None
    return AgentSpec(name=name, model=fields.get("model"), description=fields.get("description", ""))


def candidate_agent_dirs(
    workspace: Path | None = None,
    *,
    home: Path | None = None,
) -> tuple[Path, ...]:
    """Every ``agents/`` directory worth reading, project scope first.

    ``workspace`` is where a harness is pointed, so its ``agents/`` directories are
    the agents that harness can actually reach. The home sweep is one level of
    dot-directories only — personal agents, not a crawl of the disk. Anything that
    cannot be listed is skipped rather than guessed at.
    """

    found: list[Path] = []
    seen: set[Path] = set()

    def _offer(directory: Path) -> None:
        try:
            resolved = directory
            if not resolved.is_dir() or resolved in seen:
                return
        except OSError:
            return
        seen.add(resolved)
        found.append(resolved)

    roots: list[Path] = []
    if workspace is not None:
        roots.append(workspace)
    roots.append(home or Path.home())

    for root in roots:
        _offer(root / AGENT_DIRNAME)
        for pattern in ("*/" + AGENT_DIRNAME, ".*/" + AGENT_DIRNAME):
            try:
                children = sorted(root.glob(pattern))
            except OSError:
                continue
            for child in children:
                _offer(child)

    return tuple(found)


def candidate_agent_sources(
    vault_path: Path | None = None,
    *,
    home: Path | None = None,
    volumes_dir: Path | None = None,
) -> tuple[Path, ...]:
    """Places Sea-Star will look for an Osaurus roster, most specific first.

    The order is: an explicit ``SEASTAR_OSAURUS_CONFIG`` override, a copy pinned
    into the vault, the live store in the home directory, then any mounted volume
    (the shared external drive this roster is meant to live on).
    """

    base = (home or Path.home()).expanduser()
    sources: list[Path] = []

    override = os.environ.get(OSAURUS_CONFIG_ENV)
    if override:
        sources.append(Path(override).expanduser())

    if vault_path is not None:
        sources.append(Path(vault_path) / LOCAL_STATE_DIRNAME / "osaurus.json")

    sources.append(base / OSAURUS_HOME_DIRNAME)

    volumes = Path(volumes_dir) if volumes_dir is not None else Path("/Volumes")
    if volumes.is_dir():
        try:
            mounted = sorted(volume for volume in volumes.iterdir() if volume.is_dir())
        except OSError:
            mounted = []
        for volume in mounted:
            sources.append(volume / OSAURUS_HOME_DIRNAME)
            sources.extend(volume / filename for filename in OSAURUS_EXPORT_FILENAMES)

    return tuple(sources)


def _dedupe(specs: list[AgentSpec]) -> list[AgentSpec]:
    seen: set[str] = set()
    unique: list[AgentSpec] = []
    for spec in specs:
        key = spec.name.casefold()
        if key in seen:
            continue
        seen.add(key)
        unique.append(spec)
    return unique


def detect_agents(
    vault_path: Path | None = None,
    *,
    home: Path | None = None,
    volumes_dir: Path | None = None,
) -> tuple[AgentSpec, ...]:
    """The person's Osaurus agents, from the first source that yields any."""

    return detect_agent_roster(
        vault_path, home=home, volumes_dir=volumes_dir
    ).specs


@dataclass(frozen=True, slots=True)
class AgentRoster:
    """A roster, and the adapter that produced it.

    The source matters as much as the roster. ``agents`` is currently read from
    Osaurus' files, so a roster is **Osaurus'**, not the machine's — the cockpit
    has to be able to say which harness it belongs to rather than presenting one
    app's personas as everyone's. ``source`` is ``None`` when nothing was found,
    which is different from a roster found in the default location.
    """

    specs: tuple[AgentSpec, ...]
    source: str | None
    path: Path | None

    @property
    def is_empty(self) -> bool:
        return not self.specs


#: The only adapter implemented today. Named rather than hardcoded at the call
#: site so the bridge can report scope without importing a private constant.
AGENT_ADAPTER = "osaurus"

@dataclass(frozen=True, slots=True)
class AgentInstance:
    """One agent *running right now*, as opposed to one defined on disk.

    The distinction is the whole point. A definition file says a persona exists; a
    process says one is running. Both are agents, and conflating them is how a
    cockpit ends up claiming an agent is working when nothing is, or staying silent
    about one that is.

    ``pid`` identifies the instance for liveness, not identity — an instance has no
    stable name unless one can be earned from evidence, and ``pid`` is the only
    thing guaranteed to be unique right now.

    Two roles are recorded separately rather than forced into one category, because
    they genuinely overlap and collapsing them loses the truth: a chat app may
    drive Sea-Star *and* serve the model it drives it with. Filing such a process
    as either one thing is a category error — and it is the error that made the
    cockpit unreadable once already.
    """

    pid: int
    product: str
    cwd: str | None = None
    #: This instance is the one Sea-Star is actually talking to. Proof, not
    #: inference: an MCP connection is a recorded fact.
    is_attached: bool = False
    #: This instance owns a loopback port answering as a model server. True for
    #: most agents (they embed one) and for pure inference servers (they are
    #: nothing else) — so it describes what the process *does*, not what it *is*.
    serves_models: bool = False


def _ancestors(pid: int, table: Mapping[int, tuple[int, str]]) -> list[int]:
    """Every pid above ``pid``, nearest first. Stops at init rather than looping."""

    chain: list[int] = []
    current = table.get(pid, (0, ""))[0]
    while current > 1 and current not in chain and len(chain) < 64:
        chain.append(current)
        current = table.get(current, (0, ""))[0]
    return chain


def _same_product(command: str, other: str) -> bool:
    """Whether two commands belong to one product, judged without a name list.

    The bundle inside the path is the strongest signal on macOS — two commands
    under one ``.app`` are one product however differently they are invoked. Failing
    that, the executable's own stem is compared, which covers the bare-CLI case
    where a helper and its parent are both called the same thing.
    """

    def _bundle(value: str) -> str | None:
        parts = Path(value).parts
        for index, part in enumerate(parts):
            if part.endswith(".app"):
                return "/".join(parts[: index + 1])
        return None

    left, right = _bundle(command), _bundle(other)
    if left and right:
        return left == right
    if left or right:
        return False
    return Path(command).name.casefold() == Path(other).name.casefold()


def _instance_workspaces(
    pids: Iterable[int],
) -> dict[int, str]:
    """Each pid's working directory, in one ``lsof`` read.

    Where an agent is pointed is what makes a project agent belong to it, so this
    is read rather than assumed. A pid whose directory cannot be read is absent
    from the mapping rather than given a guess.
    """

    wanted = [str(pid) for pid in pids]
    if not wanted:
        return {}
    found: dict[int, str] = {}
    try:
        result = subprocess.run(
            ["lsof", "-a", "-p", ",".join(wanted), "-d", "cwd", "-Fn"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return {}
    current: int | None = None
    for line in result.stdout.splitlines():
        if line.startswith("p"):
            digits = line[1:].strip()
            current = int(digits) if digits.isdigit() else None
        elif line.startswith("n") and current is not None:
            found.setdefault(current, line[1:].strip())
    return found


def detect_agent_instances(
    *,
    table: Mapping[int, tuple[int, str]] | None = None,
    agent_pids: Iterable[int] = (),
    products: Mapping[int, str] | None = None,
    attached_pids: Iterable[int] = (),
    runtime_pids: Iterable[int] = (),
) -> tuple[AgentInstance, ...]:
    """One entry per agent *running now*, with helpers collapsed into their parent.

    A desktop agent is a dozen processes — an app, a CLI beside it, helpers,
    renderers — and counting them would call one conversation eight agents. So a
    candidate whose ancestor of the same product is itself a candidate is a helper,
    not an instance, and is dropped. What survives is the root: one root, one
    agent, however many processes it is made of.

    A surviving root with no name is still an agent, and is reported as one. An
    unnamed instance that is doing work is the common case, and declining to show
    it because no persona file exists is the same blindness the name-less CLI had.

    ``runtime_pids`` marks processes that are *only* serving models — an inference
    endpoint Sea-Star reads from, with nothing driving it. They are kept, with
    ``serves_models`` set, because a model server is a real thing on the machine
    and hiding it would be its own lie; but the flag lets a caller tell "an agent
    that happens to serve models" from "a server that serves nothing else", which
    are different facts and must not be drawn as the same kind of thing.
    """

    table = process_table() if table is None else table
    names = dict(products or {})
    candidates = {int(pid) for pid in agent_pids}
    if not candidates:
        return ()

    attached = {int(pid) for pid in attached_pids}
    runtimes = {int(pid) for pid in runtime_pids}
    workspaces = _instance_workspaces(
        pid for pid in candidates if pid in table
    )

    instances: list[AgentInstance] = []
    for pid in sorted(candidates):
        command = table.get(pid, (0, ""))[1]
        if not command:
            continue
        # A helper is a process whose parent is the same product. Dropping it here
        # is what makes a dozen-process app read as one agent.
        if any(
            _same_product(command, table.get(ancestor, (0, ""))[1])
            for ancestor in _ancestors(pid, table)
            if ancestor in candidates
        ):
            continue
        instances.append(
            AgentInstance(
                pid=pid,
                product=names.get(pid) or Path(command).name,
                cwd=workspaces.get(pid),
                is_attached=pid in attached,
                serves_models=pid in runtimes,
            )
        )
    return tuple(instances)


#: Reported alongside :data:`AGENT_ADAPTER` when the roster also came from agent
#: *files* rather than a harness's own store. The name describes the shape, not a
#: product, so a harness nobody has heard of reports honestly.
AGENT_MARKDOWN_ADAPTER = "agent-files"


def detect_agent_roster(
    vault_path: Path | None = None,
    *,
    home: Path | None = None,
    volumes_dir: Path | None = None,
    workspace: Path | None = None,
) -> AgentRoster:
    """Every agent the person has, from every family of source.

    Unioned, not first-match-wins. Returning the first non-empty source was how a
    populated harness store could hide a dozen agents written as Markdown files —
    the cockpit would then report a roster that existed, and quietly omit the rest,
    which is the same lie as reporting none at all. Sources are read in order and
    merged, so a source being empty costs nothing and a source being full never
    silences another.

    ``workspace`` is where a harness is pointed, so the ``agents/`` directories
    beneath it are the agents that harness can reach; the home sweep adds the
    personal ones that follow the person around.
    """

    specs: list[AgentSpec] = []
    adapters: list[str] = []
    first_source: Path | None = None

    for source in candidate_agent_sources(vault_path, home=home, volumes_dir=volumes_dir):
        found = _dedupe(list(read_agents(source)))
        if found:
            specs.extend(found)
            adapters.append(AGENT_ADAPTER)
            first_source = first_source or source

    for directory in candidate_agent_dirs(workspace, home=home):
        found = _dedupe(
            [spec for path in sorted(directory.glob("*.md")) if (spec := read_agent_file(path))]
        )
        if found:
            specs.extend(found)
            adapters.append(AGENT_MARKDOWN_ADAPTER)
            first_source = first_source or directory

    if not specs:
        return AgentRoster(specs=(), source=None, path=None)
    return AgentRoster(
        specs=tuple(_dedupe(specs)),
        source="+".join(dict.fromkeys(adapters)),
        path=first_source,
    )


def placement(spec: AgentSpec, runtimes) -> str:
    """Where one agent is, in one honest sentence (D-013).

    The cascade's last hop, shared between every surface that answers it: the
    panel says it in the cockpit, the MCP answer says it to a host, and both use
    this rule so they cannot disagree. Three cases, told apart rather than
    flattened:

    1. a running endpoint lists the agent's model — it is *there*;
    2. the model names a provider whose endpoint is up but not serving it;
    3. nothing answers to the model at all.

    ``runtimes`` is any iterable with ``name`` and ``models`` — a real probe or
    a test double.
    """

    model = spec.model or ""
    if not model:
        return "Rides whatever the endpoint is serving."
    for probe in runtimes:
        if model in probe.models:
            return f"Runs on {model} — served by {probe.name}."
    provider = model.split("/", 1)[0] if "/" in model else ""
    if provider:
        for probe in runtimes:
            if probe.name.casefold() == provider.casefold():
                return f"Runs on {model} — {probe.name} is up, but not serving it."
    return f"Runs on {model} — not offered by any running endpoint."
