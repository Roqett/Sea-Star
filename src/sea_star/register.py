"""The register: what this machine has decided the things on it are.

Contract:
- **One question per thing, ever.** Discovery proposes; the person answers once;
  the answer is stored and the question is never asked again. Anything that
  arrives later and matches a stored identity is recognised immediately, which
  is the whole point: a new harness must not need a code change to be seen, and
  it must not need to be re-introduced every launch either.
- **Identity is the bundle id, or the path, and never the display name.** A
  display name is a label somebody else chose and may change between versions;
  the bundle is what stays put. Getting this wrong once already cost a live
  endpoint: the register said *"Unsloth Studio"* and the bundle called itself
  *"Unsloth"*.
- **A dismissal is a decision too.** "Not a harness" is recorded rather than
  forgotten, so the cockpit stops proposing the same noise every launch. It can
  be undone, because a verdict the person cannot revise is a trap.
- **The store is `.seastar/register.json`** — inside the state directory the
  foundation permits, and the only place any of this is ever written. Nothing is
  sent anywhere, and the file contains no more than the names the person chose.
"""

from __future__ import annotations

import json
import os
from collections.abc import Iterable, Iterator
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path

from .connections import live_clients
from .harnesses import (
    KNOWN_HARNESS_APPS,
    _application_dirs,
    _bundle_identity,
    is_system_component,
    is_web_client,
)
from .recon import listening_services, model_like_services, outbound_connections

#: Where verdicts live. Overridable so tests never touch a real register.
DEFAULT_REGISTER = Path.home() / ".seastar" / "register.json"

#: The two answers a person can give about a discovered thing.
VERDICT_HARNESS = "harness"
VERDICT_NOT_A_HARNESS = "not-a-harness"

#: Where an app keeps the list of tools it has been taught to call. This file
#: exists in an app that hosts agents and almost nowhere else, which is why it
#: is the strongest single signal available without reading anything private.
MCP_CONFIG_NAMES = ("mcp.json", "mcp_config.json", "mcp_settings.json", "claude_desktop_config.json")

#: Folders in a home directory that only exist because an agent has been run.
#: A CLI harness has no bundle to find, so its state directory is its proof.
AGENT_STATE_DIRS = (
    ".claude",
    ".codex",
    ".cursor",
    ".gemini",
    ".aider",
    ".continue",
    ".cline",
    ".windsurf",
    ".ollama",
)

#: Files an agent leaves in a project it has worked in. This family is the only
#: one that proves *use* rather than installation, and it once caught a harness
#: whose own bundle gave up nothing at all.
WORKSPACE_MARKERS = (
    ".trae",
    ".cursor",
    ".opencode",
    ".claude",
    ".codex",
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
)


@dataclass(frozen=True, slots=True)
class RegisterEntry:
    """One thing, and what the person said it was."""

    identity: str
    name: str
    verdict: str
    bundle_id: str | None
    path: str | None
    decided_at: str

    @property
    def is_harness(self) -> bool:
        return self.verdict == VERDICT_HARNESS


@dataclass(frozen=True, slots=True)
class Candidate:
    """Something found on this machine that has not been decided about.

    ``evidence`` is the load-bearing part: every string in it is a fact that was
    observed, phrased so the person can judge it. A candidate that arrives
    without evidence is a demand for trust, and this app does not make those.
    """

    identity: str
    name: str
    bundle_id: str | None
    path: str | None
    evidence: tuple[str, ...]
    suggested_name: str | None = None


def _registry_path(path: Path | None = None) -> Path:
    if path is not None:
        return path
    override = os.environ.get("SEASTAR_REGISTER")
    return Path(override) if override else DEFAULT_REGISTER


def load_register(path: Path | None = None) -> dict[str, RegisterEntry]:
    """Every verdict this machine has recorded, keyed by identity.

    A register that cannot be read is treated as empty rather than fatal: a
    cockpit that refuses to start because a preferences file is malformed would
    be worse than one that asks its questions again. A malformed file is left in
    place, not overwritten, so nothing the person said is silently destroyed.
    """

    target = _registry_path(path)
    try:
        payload = json.loads(target.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    if not isinstance(payload, dict):
        return {}
    entries: dict[str, RegisterEntry] = {}
    for identity, raw in payload.get("entries", {}).items():
        if not isinstance(raw, dict):
            continue
        try:
            entries[identity] = RegisterEntry(
                identity=identity,
                name=str(raw.get("name", identity)),
                verdict=str(raw.get("verdict", VERDICT_NOT_A_HARNESS)),
                bundle_id=raw.get("bundle_id"),
                path=raw.get("path"),
                decided_at=str(raw.get("decided_at", "")),
            )
        except (TypeError, ValueError):
            continue
    return entries


def save_register(entries: dict[str, RegisterEntry], path: Path | None = None) -> Path:
    """Write every verdict, atomically, to the state directory."""

    target = _registry_path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "entries": {
            identity: asdict(entry) for identity, entry in sorted(entries.items())
        }
    }
    staging = target.with_suffix(".tmp")
    staging.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    staging.replace(target)
    return target


def decide(
    identity: str,
    *,
    name: str,
    is_harness: bool,
    bundle_id: str | None = None,
    path: str | None = None,
    register: Path | None = None,
) -> RegisterEntry:
    """Record what the person said, and return the entry as stored."""

    entries = load_register(register)
    entry = RegisterEntry(
        identity=identity,
        name=name,
        verdict=VERDICT_HARNESS if is_harness else VERDICT_NOT_A_HARNESS,
        bundle_id=bundle_id,
        path=path,
        decided_at=datetime.now(UTC).isoformat(timespec="seconds"),
    )
    entries[identity] = entry
    save_register(entries, register)
    return entry


def forget(identity: str, *, register: Path | None = None) -> None:
    """Undo a verdict, so the question can be asked again."""

    entries = load_register(register)
    if entries.pop(identity, None) is not None:
        save_register(entries, register)


def known_harness_names(register: dict[str, RegisterEntry] | None = None) -> tuple[str, ...]:
    """Every name this machine has agreed is a harness, for recognition.

    Fed to :func:`sea_star.recon.model_like_services`, which is how a local port
    that names no runtime still gets recognised: the register does the work a
    list of app names cannot.
    """

    entries = load_register() if register is None else register
    names = {entry.name for entry in entries.values() if entry.is_harness}
    names.update(entry.bundle_id for entry in entries.values() if entry.bundle_id)
    names.update(entry.path for entry in entries.values() if entry.path)
    return tuple(sorted(name for name in names if name))


def recognised_names(
    register: dict[str, RegisterEntry] | None = None,
    home: Path | None = None,
) -> tuple[str, ...]:
    """Every string by which this machine recognises a harness.

    One definition, because two callers need it and a second copy would drift:
    the cockpit's report and the MCP answer must agree about the same machine.
    Four sources, none of them a gate on what exists:

    - **the register** — what the person has answered, which is the only source
      that can name something nobody has heard of;
    - **the attached hosts** — an app driving Sea-Star right now is a harness by
      demonstration;
    - **the seed table** — the apps this build ships hints for, so a cold machine
      with an empty register is not blank;
    - their **paths as well as their names**, because a register entry and a
      bundle rarely agree on spelling.
    """

    entries = load_register() if register is None else register
    names: set[str] = set(known_harness_names(entries))
    for client in live_clients():
        if client.name:
            names.add(client.name)
        if client.app_path:
            names.add(client.app_path)
    for bundle_id, brand, path in _installed_apps():
        if bundle_id not in KNOWN_HARNESS_APPS:
            continue
        names.add(brand)
        names.add(path)
        names.add(bundle_id)
    return tuple(sorted(name for name in names if name))


# --- discovery --------------------------------------------------------------


def _installed_apps() -> Iterator[tuple[str | None, str | None, str]]:
    """``(bundle id, brand name, path)`` for every installed app, seed or not.

    The seed table only supplies a *suggested* name. What exists is decided by
    the disk, not by the table — the table is a hint and never a gate.
    """

    for directory in _application_dirs():
        if not directory.is_dir():
            continue
        try:
            apps = sorted(directory.glob("*.app"))
        except OSError:
            continue
        for app in apps:
            identity = _bundle_identity(app)
            if identity is None:
                continue
            bundle_id, display = identity
            yield bundle_id, KNOWN_HARNESS_APPS.get(bundle_id, display), str(app)


def mcp_configs(home: Path | None = None) -> tuple[tuple[str, Path], ...]:
    """``(owner label, path)`` for every MCP tool list found on this machine.

    Only the *presence* of the file is reported, never its contents: which tools
    another app has been taught to call is that app's business, and a cockpit
    earns its place by knowing what is on the machine, not by reading it out.
    """

    base = home or Path.home()
    roots = [
        base / "Library" / "Application Support",
        base / ".config",
        base / "Library" / "Preferences",
    ]
    found: list[tuple[str, Path]] = []
    for root in roots:
        if not root.is_dir():
            continue
        try:
            owners = sorted(entry for entry in root.iterdir() if entry.is_dir())
        except OSError:
            continue
        for owner in owners:
            for name in MCP_CONFIG_NAMES:
                candidate = owner / name
                if candidate.is_file():
                    found.append((owner.name, candidate))
                # One level deeper: some apps nest config under `data/` or `User/`.
                try:
                    nested = sorted(child for child in owner.iterdir() if child.is_dir())
                except OSError:
                    continue
                for child in nested:
                    deep = child / name
                    if deep.is_file():
                        found.append((owner.name, deep))
    return tuple(found)


def agent_state_dirs(home: Path | None = None) -> tuple[tuple[str, Path], ...]:
    """``(name, path)`` for every agent state directory a CLI harness left behind."""

    base = home or Path.home()
    found: list[tuple[str, Path]] = []
    for name in AGENT_STATE_DIRS:
        path = base / name
        if path.is_dir():
            found.append((name.lstrip("."), path))
    return tuple(found)


def workspace_markers(workspace: Path | None = None) -> tuple[Path, ...]:
    """Agent artefacts left in a project — the only family that proves use."""

    if workspace is None or not workspace.is_dir():
        return ()
    return tuple(
        marker for marker in (workspace / name for name in WORKSPACE_MARKERS) if marker.exists()
    )


def discover(
    *,
    register: dict[str, RegisterEntry] | None = None,
    workspace: Path | None = None,
    home: Path | None = None,
    include_vocabulary: bool = False,
) -> tuple[Candidate, ...]:
    """Everything on this machine worth asking about, with the evidence for it.

    Anything already decided is left out — that is what makes the question
    once-only. Candidates are returned in a stable order so the list does not
    shuffle between reads, and the same thing found by two families is offered
    once, with both pieces of evidence, rather than twice.

    ``include_vocabulary`` turns on the one family that reads inside app bundles.
    It is off by default because it is the slow one: a cockpit poll has to stay
    quick, so the heavy read belongs to an explicit scan.
    """

    decided = load_register() if register is None else register
    agreed_names = known_harness_names(decided)
    pending: dict[str, Candidate] = {}

    def offer(
        identity: str,
        name: str,
        *,
        bundle_id: str | None = None,
        path: str | None = None,
        evidence: str,
        suggested: str | None = None,
    ) -> None:
        # Two declared roles are barred from harness classification entirely, so
        # no family can raise them however much traffic they generate. See
        # `harnesses.is_web_client` / `is_system_component` for why these are
        # categories and not names.
        if _barred(path):
            return
        if identity in decided:
            return
        existing = pending.get(identity)
        if existing is None:
            pending[identity] = Candidate(
                identity=identity,
                name=name,
                bundle_id=bundle_id,
                path=path,
                evidence=(evidence,),
                suggested_name=suggested,
            )
            return
        if evidence not in existing.evidence:
            pending[identity] = Candidate(
                identity=existing.identity,
                name=existing.name,
                bundle_id=existing.bundle_id,
                path=existing.path,
                evidence=existing.evidence + (evidence,),
                suggested_name=existing.suggested_name or suggested,
            )

    # 1. What is answering on this machine, and who owns it.
    model_ports = {service.port for service in model_like_services(known_apps=agreed_names)}
    for service in listening_services():
        if service.app_path is None:
            continue
        identity = _identity_for(service.app_path, service.app_name)
        if service.port in model_ports:
            evidence = f"serving a model on {service.base_url}"
        else:
            evidence = f"listening on {service.address}:{service.port}"
        offer(
            identity,
            service.app_name or Path(service.app_path).stem,
            path=service.app_path,
            evidence=evidence,
        )

    # 2. What is talking to the outside world right now. Deliberately *not* a
    #    reason to ask: nearly every networked app reaches outside, so this
    #    family raised browsers, messengers and updaters as candidates until it
    #    was cut back. Traffic *enriches* a thing already suspected of being a
    #    harness — it is applied at the end, below — and never creates one.
    outside: dict[str, set[str]] = {}
    for connection in outbound_connections():
        if connection.app_path is None or connection.is_local_link:
            continue
        outside.setdefault(connection.app_path, set()).add(connection.remote_host)

    # 3. What has been taught to call tools — the strongest signal on disk. An
    #    app that keeps its own tool list is asked about *once*: the finding is
    #    attached to the app when the folder names one, and only stands alone
    #    when nothing installed answers to that name.
    by_label = _app_index()
    for owner, config in mcp_configs(home):
        evidence = f"keeps a list of tools it can call ({config.name})"
        known = by_label.get(owner.casefold())
        if known is not None:
            bundle_id, brand, path = known
            offer(bundle_id, brand, bundle_id=bundle_id, path=path, evidence=evidence)
        else:
            offer(f"mcp:{config}", owner, path=str(config), evidence=evidence)

    # 4. CLI harnesses, which have no bundle and prove themselves with state.
    for name, path in agent_state_dirs(home):
        offer(
            f"state:{path}",
            name,
            path=str(path),
            evidence=f"keeps agent state in {path.name}/",
        )

    # 5. What an agent left in the project it worked on.
    for marker in workspace_markers(workspace):
        offer(
            f"marks:{marker}",
            marker.name,
            path=str(marker),
            evidence=f"left {marker.name} in {marker.parent}",
        )

    # 6. Apps this build's seed table already recognises. Being in the seed is
    #    itself the evidence, and the suggested name makes the answer one click.
    #    Every other installed app is deliberately *not* offered: "installed" is
    #    not evidence of being a harness, and thirty-one questions is noise, not
    #    onboarding. Nothing is hidden — every app stays visible in the report —
    #    it simply is not accused of being a harness on no grounds.
    for bundle_id, brand, path in _installed_apps():
        if bundle_id not in KNOWN_HARNESS_APPS:
            continue
        offer(
            bundle_id,
            brand,
            bundle_id=bundle_id,
            path=path,
            evidence="a harness app this build already recognises",
            suggested=brand,
        )

    # 7. What an app says about itself, when the caller wants the slower read.
    #    This is the family that finds an app the seed table has never heard of.
    if include_vocabulary:
        for path, words in vocabulary_hits():
            offer(
                f"vocab:{path}",
                Path(path).stem,
                path=path,
                evidence=f"names {', '.join(words)} inside its own code",
            )

    # Attach the traffic evidence to whatever the other families found. This is
    # the whole of what outbound contributes: a fact about something already
    # worth asking about, never a question of its own.
    if outside:
        for identity, candidate in list(pending.items()):
            for app_path, hosts in outside.items():
                if candidate.path != app_path:
                    continue
                evidence = f"connected to {len(hosts)} host(s) outside this machine"
                if evidence not in candidate.evidence:
                    pending[identity] = Candidate(
                        identity=candidate.identity,
                        name=candidate.name,
                        bundle_id=candidate.bundle_id,
                        path=candidate.path,
                        evidence=candidate.evidence + (evidence,),
                        suggested_name=candidate.suggested_name,
                    )

    return tuple(pending[key] for key in sorted(pending))


def _barred(app_path: str | None) -> bool:
    """Whether an app is excluded from harness classification by its own role."""

    if app_path is None:
        return False
    if is_system_component(app_path):
        return True
    return is_web_client(Path(app_path), app_path)


def _app_index() -> dict[str, tuple[str, str, str]]:
    """``{label: (bundle id, brand, path)}`` for every installed app.

    Every label an app answers to goes in — its brand, its bundle's own display
    name, and its folder — because a support folder is named by whichever of
    those the developer happened to use, and matching only one of them is how the
    same app ends up asked about twice.
    """

    index: dict[str, tuple[str, str, str]] = {}
    for bundle_id, brand, path in _installed_apps():
        identity = _bundle_identity(Path(path))
        labels = {brand, Path(path).stem, bundle_id}
        if identity is not None:
            labels.add(identity[1])
        for label in labels:
            if label:
                index.setdefault(label.casefold(), (bundle_id, brand, path))
    return index


def _identity_for(app_path: str, app_name: str | None) -> str:
    """The stable identity of an app: its bundle id when readable, else its path."""

    identity = _bundle_identity(Path(app_path))
    return identity[0] if identity is not None else app_path


def summarise(candidates: Iterable[Candidate]) -> str:
    """A one-line count for a CLI header, in words rather than a bare number."""

    items = list(candidates)
    if not items:
        return "Nothing new to ask about."
    return f"{len(items)} thing(s) on this machine have not been decided yet."


#: The **strong** words: the protocol an app speaks when it hosts agents. These
#: are the only ones allowed to raise a candidate, and testing is why. Brand
#: names are worthless on their own — Firefox, DuckDuckGo and ProtonVPN all
#: "name openai" because they ship lists of domains they block or trust, and a
#: browser is not a harness. A tool list or an MCP handshake is a different
#: kind of string entirely: an app has those because it *drives* agents.
PROTOCOL_VOCABULARY: tuple[str, ...] = (
    "mcpServers",
    "modelcontextprotocol",
)

#: Supporting words. Reported as colour in the evidence line — "names claude,
#: openai and mcpServers" is a far more useful thing for a person to judge than
#: a yes/no — but never sufficient alone, for the reason above.
AGENT_VOCABULARY: tuple[str, ...] = (
    "anthropic",
    "openai",
    "claude",
    "codex",
    "gemini",
    "copilot",
    "llama-index",
    "langchain",
    "chat/completions",
    "tool_calls",
    "system_prompt",
    "huggingface",
) + PROTOCOL_VOCABULARY

#: Files that *are* the app's code, whatever their size. An Electron app puts
#: every line it owns in one archive, and a small archive is still the whole
#: program — a size floor alone would skip it and find nothing.
_CODE_ARCHIVE_SUFFIXES = (".asar", ".js", ".mjs", ".py", ".node")

#: How much of one file to read, and how many files per app. The bundle is not
#: indexed and never walked in full: an Electron app keeps all of its logic in
#: one archive, and reading that archive's first stretch is enough to see what
#: vocabulary it carries. Bounded on purpose, because this runs on a machine
#: somebody is using.
_VOCAB_READ_BYTES = 40_000_000
_VOCAB_FILES_PER_APP = 3


def _vocabulary_in(path: Path) -> tuple[str, ...]:
    """Which agent words appear in a file, read in bounded chunks."""

    found: set[str] = set()
    try:
        with path.open("rb") as handle:
            blob = handle.read(_VOCAB_READ_BYTES)
    except OSError:
        return ()
    for word in AGENT_VOCABULARY:
        if word.encode() in blob:
            found.add(word)
    return tuple(sorted(found))


def vocabulary_hits(
    *,
    system_dir: Path | None = None,
    home: Path | None = None,
) -> tuple[tuple[str, tuple[str, ...]], ...]:
    """``(app path, words found)`` for every app whose own code names agents.

    The slow, explicit family. It exists because two of the harnesses on this
    machine — an IDE and a tool for switching between agent providers — gave up
    nothing to any other signal, and one of them was invisible until the search
    used agent words instead of provider words. A *vocabulary* reaches software
    nobody has written yet; a list of app names cannot.

    Bounded, and *qualified*: only an app carrying a protocol word is returned,
    so six browsers and utilities do not arrive as candidates wearing a brand
    name they merely happened to ship a blocklist for.
    """

    results: list[tuple[str, tuple[str, ...]]] = []
    for _bundle_id, _brand, path_text in _installed_apps():
        app = Path(path_text)
        candidates: list[Path] = []
        macos = app / "Contents" / "MacOS"
        if macos.is_dir():
            candidates.extend(
                sorted(
                    (
                        entry
                        for entry in macos.iterdir()
                        if entry.is_file() and entry.stat().st_size > 200_000
                    ),
                    key=lambda entry: entry.stat().st_size,
                    reverse=True,
                )[:1]
            )
        resources = app / "Contents" / "Resources"
        if resources.is_dir():
            candidates.extend(
                sorted(
                    (
                        entry
                        for entry in resources.iterdir()
                        if entry.is_file()
                        and (
                            entry.stat().st_size > 100_000
                            or entry.name.endswith(_CODE_ARCHIVE_SUFFIXES)
                        )
                    ),
                    key=lambda entry: entry.stat().st_size,
                    reverse=True,
                )[: _VOCAB_FILES_PER_APP - 1]
            )
        words: set[str] = set()
        for candidate in candidates[:_VOCAB_FILES_PER_APP]:
            words.update(_vocabulary_in(candidate))
        # A candidate is raised only by a protocol word. Without that bar the
        # browsers arrive: they carry every AI brand name going, as a blocklist.
        if any(word in words for word in PROTOCOL_VOCABULARY):
            results.append((path_text, tuple(sorted(words))))
    return tuple(results)
