"""Discover the person's Osaurus agents, so the cockpit can draw one per persona.

Osaurus (a local macOS agent harness) keeps its roster under ``~/.osaurus/`` and
can export the whole roster as one declarative document (``osaurus config
export``). Sea-Star only ever reads *that an agent exists, what it is called and
which model it is bound to* — never prompts, secrets or tool grants — so the graph
can show a persona beside the harness that runs its model. This module is a pure
read of files the person already owns; it never touches the network.

Two sources are understood, because the person's roster can arrive either way:

- a **declarative export document** (``agents:`` list, each with a ``name`` and
  optional ``model``), which is what moves cleanly between accounts on a shared
  drive; and
- the **live store** (``~/.osaurus/agents/*.json`` and
  ``~/.osaurus/config/default-agent.json``), read tolerantly so an agent file the
  app does not fully understand still yields a name and a model.

An entry without a name is skipped rather than given a placeholder, so the graph
never shows a phantom persona.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path

from .config import LOCAL_STATE_DIRNAME

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
    """

    raw_name = entry.get("name") or entry.get("id") or fallback_name
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
    """Every agent the live ``.osaurus`` store exposes, best-effort."""

    specs: list[AgentSpec] = []
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
    default = root / "config" / "default-agent.json"
    if default.is_file():
        data = _read_json(default)
        if isinstance(data, dict):
            spec = _agent_from_entry(data)
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

    for source in candidate_agent_sources(vault_path, home=home, volumes_dir=volumes_dir):
        specs = _dedupe(list(read_agents(source)))
        if specs:
            return tuple(specs)
    return ()
