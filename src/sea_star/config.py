"""Configuration loading and local-runtime autodetection.

Contract:
- Resolution order is: explicit CLI argument > environment variable >
  ``seastar.toml`` in the working directory (or ``~/.config/seastar/config.toml``)
  > autodetection > hard failure.
- Autodetection never guesses silently. It probes known local OpenAI-compatible
  endpoints and adopts the first one that answers with a model list; if none
  answer it raises :class:`ConfigError` rather than inventing a default.
- Egress is opt-in: the only endpoint SeaStar will talk to is the one resolved
  here, which is local unless the operator set it by hand.
"""

from __future__ import annotations

import asyncio
import json
import os
import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import urlsplit

import httpx

CONFIG_FILENAME = "seastar.toml"
LOCAL_STATE_DIRNAME = ".seastar"

DEFAULT_API_KEY = "seastar-local"

LOCAL_HOST = "127.0.0.1"

#: The one runtime Sea-Star treats specially. Osaurus hides the model it is
#: actually bound to behind a placeholder over its API (``/v1/models`` answers
#: only ``foundation``), so its real model has to be read from Osaurus's own
#: config rather than believed from the endpoint — see
#: :func:`read_osaurus_default_model`.
OSAURUS_RUNTIME_NAME = "osaurus"
OSAURUS_HOME_DIRNAME = ".osaurus"
OSAURUS_DEFAULT_AGENT = ("config", "default-agent.json")

KNOWN_RUNTIMES: tuple[tuple[str, str], ...] = (
    ("osaurus", "http://127.0.0.1:1337/v1"),
    ("ollama", "http://127.0.0.1:11434/v1"),
    ("lmstudio", "http://127.0.0.1:1234/v1"),
    ("unsloth", "http://127.0.0.1:8888/v1"),
    ("llamacpp", "http://127.0.0.1:8080/v1"),
    ("omlx", "http://127.0.0.1:8000/v1"),
    ("vllm", "http://127.0.0.1:8000/v1"),
)

EXTRA_SCAN_PORTS: tuple[int, ...] = (
    8009, 8000, 11434, 1234, 1337, 8080, 8888, 5000, 5001, 7860, 4000,
    8081, 8082, 8088, 8090, 9000, 9001, 10000, 3000, 12345,
)

GENERIC_OWNERS: frozenset[str] = frozenset(
    {"library", "user", "system", "openai", "organization_owner"}
)


def _port_of(base_url: str) -> int:
    return urlsplit(base_url).port or 0


NAMED_PORTS: dict[int, str] = {
    _port_of(base_url): name for name, base_url in reversed(KNOWN_RUNTIMES)
}


def scan_ports() -> tuple[int, ...]:
    """Every localhost port worth sweeping for an OpenAI-compatible server.

    Harness ports are not fixed — oMLX's documented default is 8000, but the same
    person often runs a second copy on 8009, and other machines pick other ports.
    So we sweep a standard set rather than trusting one address per harness.
    Known-harness ports come first (in :data:`KNOWN_RUNTIMES` order), then the
    extras. ``SEASTAR_SCAN_PORTS`` (comma-separated) replaces the set wholesale.
    """

    override = os.environ.get("SEASTAR_SCAN_PORTS")
    if override:
        ports: list[int] = []
        for chunk in override.split(","):
            chunk = chunk.strip()
            if chunk.isdigit() and 0 < int(chunk) < 65536 and int(chunk) not in ports:
                ports.append(int(chunk))
        return tuple(ports)
    ports: list[int] = []
    for _name, base_url in KNOWN_RUNTIMES:
        port = _port_of(base_url)
        if port and port not in ports:
            ports.append(port)
    for port in EXTRA_SCAN_PORTS:
        if port not in ports:
            ports.append(port)
    return tuple(ports)

OBSIDIAN_CONFIG_NAME = "obsidian.json"

PROBE_TIMEOUT_SECONDS = 1.5

VAULT_SOURCE_ENV = "env"
VAULT_SOURCE_CONFIG = "toml"
VAULT_SOURCE_OBSIDIAN = "obsidian"


class ConfigError(RuntimeError):
    """Raised when configuration is missing, invalid, or unreachable."""


@dataclass(frozen=True, slots=True)
class MCPServerSpec:
    """An external MCP server SeaStar should consume as a tool source."""

    name: str
    command: str
    args: tuple[str, ...] = ()
    env: tuple[tuple[str, str], ...] = ()
    include: tuple[str, ...] = ()
    exclude: tuple[str, ...] = ()

    def env_dict(self) -> dict[str, str]:
        return dict(self.env)

    def allows(self, tool_name: str) -> bool:
        """Whether this server's ``tool_name`` should be exposed to the agent.

        An empty ``include`` means "everything not excluded"; a non-empty one is
        an allowlist. ``exclude`` always wins. Curating here — at connect time —
        is what keeps the agent's tool menu small enough to choose well.
        """

        if self.include and tool_name not in self.include:
            return False
        return tool_name not in self.exclude


@dataclass(frozen=True, slots=True)
class Config:
    """Fully resolved configuration. Immutable once loaded."""

    vault_path: Path
    runtime_name: str
    base_url: str
    model: str
    api_key: str = DEFAULT_API_KEY
    max_steps: int = 8
    temperature: float = 0.2
    servers: tuple[MCPServerSpec, ...] = field(default_factory=tuple)

    @property
    def state_dir(self) -> Path:
        return self.vault_path / LOCAL_STATE_DIRNAME


def _find_config_file(explicit: Path | None) -> Path | None:
    if explicit is not None:
        if not explicit.is_file():
            raise ConfigError(f"Config file not found: {explicit}")
        return explicit
    candidates = (
        Path.cwd() / CONFIG_FILENAME,
        Path.home() / ".config" / "seastar" / "config.toml",
    )
    return next((path for path in candidates if path.is_file()), None)


def _parse_servers(raw: object) -> tuple[MCPServerSpec, ...]:
    if raw is None:
        return ()
    if not isinstance(raw, list):
        raise ConfigError("[[mcp.servers]] must be a list of tables.")
    specs: list[MCPServerSpec] = []
    for entry in raw:
        if not isinstance(entry, dict) or "name" not in entry or "command" not in entry:
            raise ConfigError("Each [[mcp.servers]] entry needs a name and a command.")
        specs.append(
            MCPServerSpec(
                name=str(entry["name"]),
                command=str(entry["command"]),
                args=tuple(str(a) for a in entry.get("args", ())),
                env=tuple((str(k), str(v)) for k, v in entry.get("env", {}).items()),
                include=tuple(str(t) for t in entry.get("include", ())),
                exclude=tuple(str(t) for t in entry.get("exclude", ())),
            )
        )
    return tuple(specs)


async def probe_endpoint(
    base_url: str, *, timeout: float = PROBE_TIMEOUT_SECONDS
) -> tuple[list[str], str | None] | None:
    """Return ``(model_ids, owner)`` at ``base_url``, or ``None`` if unreachable.

    ``owner`` is the server's self-reported ``owned_by`` — oMLX says ``"omlx"``,
    vLLM says ``"vllm"`` — so a server found on an unexpected port can still name
    itself. Generic values (``library``, ``user`` …) are dropped so we fall back
    to the port's known name instead. Never raises for connectivity problems — an
    unreachable endpoint is a signal, not an error, so a sweep can move on.
    """

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.get(f"{base_url.rstrip('/')}/models")
            response.raise_for_status()
            payload = response.json()
    except (httpx.HTTPError, ValueError):
        return None
    data = payload.get("data", ())
    models = [str(item["id"]) for item in data if item.get("id")]
    if not models:
        return None
    owner = next((str(item["owned_by"]) for item in data if item.get("owned_by")), None)
    if owner in GENERIC_OWNERS:
        owner = None
    return models, owner


async def probe_base_url(base_url: str, *, timeout: float = PROBE_TIMEOUT_SECONDS) -> list[str] | None:
    """Return the model ids advertised at ``base_url``, or ``None`` if unreachable."""

    answer = await probe_endpoint(base_url, timeout=timeout)
    return answer[0] if answer else None


@dataclass(frozen=True, slots=True)
class RuntimeProbe:
    """One local inference server that answered, with the models it advertises."""

    name: str
    base_url: str
    models: tuple[str, ...]

    @property
    def model(self) -> str:
        return self.models[0]


async def probe_runtimes(*, timeout: float = PROBE_TIMEOUT_SECONDS) -> tuple[RuntimeProbe, ...]:
    """Every local runtime answering *right now*, in :func:`scan_ports` order.

    People run more than one harness at once — Osaurus *and* oMLX, say — and each
    picks its own port (oMLX on 8000 here, 8009 there), so this sweeps the whole
    standard port set rather than trusting one address per harness. Probes run
    concurrently to keep the survey inside a single timeout. A responder is named
    by its self-reported ``owned_by`` when that is specific, else by the port's
    known harness, else ``"local"``.
    """

    ports = scan_ports()
    answers = await asyncio.gather(
        *(
            probe_endpoint(f"http://{LOCAL_HOST}:{port}/v1", timeout=timeout)
            for port in ports
        )
    )
    probes: list[RuntimeProbe] = []
    for port, answer in zip(ports, answers):
        if answer is None:
            continue
        models, owner = answer
        name = owner or NAMED_PORTS.get(port) or "local"
        if name == OSAURUS_RUNTIME_NAME:
            # Osaurus advertises only the placeholder ``foundation``; the model it
            # is really bound to lives in its own config. Trust that over the
            # endpoint, or the cockpit would name a model nobody can select.
            configured = read_osaurus_default_model()
            if configured:
                models = [configured]
        probes.append(
            RuntimeProbe(
                name=name,
                base_url=f"http://{LOCAL_HOST}:{port}/v1",
                models=tuple(models),
            )
        )
    return tuple(probes)


async def detect_runtime(*, probes: tuple[RuntimeProbe, ...] | None = None) -> tuple[str, str, str]:
    """Probe local runtimes and return ``(name, base_url, model)``.

    Adopts the first runtime that answers, in :func:`scan_ports` order, so a
    single-runtime machine behaves exactly as before. Pass ``probes`` (from
    :func:`probe_runtimes`) to reuse an existing survey instead of probing the
    network again. Raises :class:`ConfigError` when nothing answers — an
    unconfigured machine should be told to start a runtime, not handed a silent
    fallback.
    """

    if probes is None:
        probes = await probe_runtimes()
    if probes:
        first = probes[0]
        return first.name, first.base_url, first.model
    probed = ", ".join(str(port) for port in scan_ports())
    raise ConfigError(
        "No local inference server answered. Start Osaurus (osaurus serve), "
        "Ollama, LM Studio, llama.cpp, MLX (oMLX), vLLM or Unsloth Studio, or set "
        f"[inference].base_url in {CONFIG_FILENAME}. Swept localhost ports: {probed}"
    )


def _obsidian_config_paths(home: Path) -> tuple[Path, ...]:
    """Places Obsidian keeps its own config, per platform."""

    paths = [
        home / "Library" / "Application Support" / "obsidian" / OBSIDIAN_CONFIG_NAME,
        home / ".config" / "obsidian" / OBSIDIAN_CONFIG_NAME,
    ]
    appdata = os.environ.get("APPDATA")
    if appdata:
        paths.append(Path(appdata) / "obsidian" / OBSIDIAN_CONFIG_NAME)
    return tuple(paths)


def detect_vault_candidates(home: Path | None = None) -> tuple[Path, ...]:
    """Every Obsidian-known vault that still exists, best candidate first.

    Obsidian records each vault it knows in ``obsidian.json``; the entry flagged
    ``open`` is the one the user last used, and the rest follow most-recently-used
    first. This is the pick-list the app offers; ``detect_vault`` takes its head.
    Reading it means SeaStar can be truly zero-config for anyone who already has
    Obsidian installed.
    """

    base = (home or Path.home()).expanduser()
    entries: list[dict] = []
    for candidate in _obsidian_config_paths(base):
        try:
            data = json.loads(candidate.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
        vaults = data.get("vaults")
        if not isinstance(vaults, dict):
            continue
        entries.extend(
            entry
            for entry in vaults.values()
            if isinstance(entry, dict) and entry.get("path")
        )
    entries.sort(key=lambda entry: (bool(entry.get("open")), entry.get("ts", 0)), reverse=True)
    candidates: list[Path] = []
    for entry in entries:
        path = Path(str(entry["path"])).expanduser()
        if path.is_dir():
            resolved = path.resolve()
            if resolved not in candidates:
                candidates.append(resolved)
    return tuple(candidates)


def detect_vault(home: Path | None = None) -> Path | None:
    """The user's best Obsidian vault, or ``None`` when Obsidian is absent."""

    candidates = detect_vault_candidates(home)
    return candidates[0] if candidates else None


def read_osaurus_default_model(home: Path | None = None) -> str | None:
    """The model Osaurus is actually bound to, read from Osaurus's own config.

    Osaurus never names that model over its API — ``/v1/models`` answers only the
    placeholder ``foundation`` — so when the person has pointed Osaurus at a real
    provider (oMLX, say) the binding is visible only in
    ``~/.osaurus/config/default-agent.json``. Returns ``None`` when that file is
    absent, unreadable or nameless, so a caller can fall back to the probe.
    """

    path = (
        (home or Path.home())
        .expanduser()
        .joinpath(OSAURUS_HOME_DIRNAME, *OSAURUS_DEFAULT_AGENT)
    )
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    if not isinstance(data, dict):
        return None
    model = data.get("defaultModel") or data.get("default_model") or data.get("model")
    if isinstance(model, str) and model.strip():
        return model.strip()
    return None


def read_config_file(path: Path | None = None) -> dict:
    """Read and parse the active ``seastar.toml``, or ``{}`` when none exists."""

    config_file = _find_config_file(path)
    if config_file is None:
        return {}
    with config_file.open("rb") as handle:
        return tomllib.load(handle)


def resolve_vault(
    data: dict, *, autodetect: bool = True, home: Path | None = None
) -> tuple[Path, str]:
    """Resolve the vault path and how it was chosen.

    Order is explicit ``SEASTAR_VAULT`` > ``[vault]`` in the config file > Obsidian
    autodetection > fail loud. Returns ``(path, source)`` with ``source`` one of
    ``env`` / ``toml`` / ``obsidian``, so a caller can explain the choice.
    """

    env_vault = os.environ.get("SEASTAR_VAULT")
    toml_vault = data.get("vault")
    if env_vault:
        vault_path = Path(env_vault).expanduser().resolve()
        source = VAULT_SOURCE_ENV
    elif toml_vault:
        vault_path = Path(str(toml_vault)).expanduser().resolve()
        source = VAULT_SOURCE_CONFIG
    else:
        detected_vault = detect_vault(home) if autodetect else None
        if detected_vault is None:
            raise ConfigError(
                f"No vault configured and no Obsidian vault found. Run "
                f"`sea-star init --vault <path>` or set [vault] in {CONFIG_FILENAME}."
            )
        vault_path = detected_vault
        source = VAULT_SOURCE_OBSIDIAN
    if not vault_path.is_dir():
        raise ConfigError(f"Vault path is not a directory: {vault_path}")
    return vault_path, source


async def load_config(
    path: Path | None = None,
    *,
    autodetect: bool = True,
    probes: tuple[RuntimeProbe, ...] | None = None,
) -> Config:
    """Resolve a complete :class:`Config`, failing loud on anything missing."""

    data = read_config_file(path)

    vault_path, _vault_source = resolve_vault(data, autodetect=autodetect)

    inference = data.get("inference", {})
    if not isinstance(inference, dict):
        raise ConfigError("[inference] must be a table.")

    base_url = os.environ.get("SEASTAR_BASE_URL") or inference.get("base_url")
    model = os.environ.get("SEASTAR_MODEL") or inference.get("model")
    api_key = os.environ.get("SEASTAR_API_KEY") or inference.get("api_key") or DEFAULT_API_KEY
    runtime_name = os.environ.get("SEASTAR_RUNTIME") or inference.get("runtime") or "custom"

    if not base_url:
        if not autodetect:
            raise ConfigError("No inference endpoint configured and autodetection is disabled.")
        runtime_name, base_url, detected_model = await detect_runtime(probes=probes)
        model = model or detected_model

    if not model:
        if not autodetect:
            raise ConfigError("No model configured and autodetection is disabled.")
        models = await probe_base_url(str(base_url))
        if not models:
            raise ConfigError(f"No model configured and {base_url} advertised none.")
        model = models[0]

    max_steps = int(os.environ.get("SEASTAR_MAX_STEPS") or inference.get("max_steps") or 8)
    temperature = float(inference.get("temperature", 0.2))
    servers = _parse_servers(data.get("mcp", {}).get("servers") if isinstance(data.get("mcp", {}), dict) else None)

    return Config(
        vault_path=vault_path,
        runtime_name=str(runtime_name),
        base_url=str(base_url),
        model=str(model),
        api_key=str(api_key),
        max_steps=max_steps,
        temperature=temperature,
        servers=servers,
    )


def write_default_config(vault_path: Path, *, model: str = "", base_url: str = "") -> Path:
    """Write a ``seastar.toml`` into the vault. Returns the file path."""

    vault_path = vault_path.expanduser().resolve()
    lines = [
        "# Sea-Star configuration. Generated by `sea-star init`.",
        "",
        f'vault = "{vault_path}"',
        "",
        "[inference]",
        '# Leave base_url empty to let Sea-Star autodetect a local runtime on startup.',
        f'base_url = "{base_url}"' if base_url else '# base_url = "http://127.0.0.1:11434/v1"',
        f'model = "{model}"' if model else '# model = "your-model-name"',
        f'api_key = "{DEFAULT_API_KEY}"',
        "max_steps = 8",
        "temperature = 0.2",
        "",
        "# Consume other MCP servers as Sea-Star tools. Uncomment to enable.",
        "# [[mcp.servers]]",
        '# name = "obsidian"',
        '# command = "npx"',
        '# args = ["-y", "obsidian-mcp", "/absolute/path/to/your/vault"]',
        '# include = ["search_notes"]  # optional allowlist; empty = every tool',
        '# exclude = []                 # optional denylist; always wins',
        "",
    ]
    destination = vault_path / CONFIG_FILENAME
    destination.write_text("\n".join(lines), encoding="utf-8")
    return destination
