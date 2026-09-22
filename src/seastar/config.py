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

import json
import os
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

import httpx

CONFIG_FILENAME = "seastar.toml"
LOCAL_STATE_DIRNAME = ".seastar"

DEFAULT_API_KEY = "seastar-local"

KNOWN_RUNTIMES: tuple[tuple[str, str], ...] = (
    ("ollama", "http://127.0.0.1:11434/v1"),
    ("lmstudio", "http://127.0.0.1:1234/v1"),
    ("llamacpp", "http://127.0.0.1:8080/v1"),
    ("mlx", "http://127.0.0.1:8080/v1"),
    ("vllm", "http://127.0.0.1:8000/v1"),
    ("unsloth", "http://127.0.0.1:8000/v1"),
)

OBSIDIAN_CONFIG_NAME = "obsidian.json"

PROBE_TIMEOUT_SECONDS = 1.5


class ConfigError(RuntimeError):
    """Raised when configuration is missing, invalid, or unreachable."""


@dataclass(frozen=True, slots=True)
class MCPServerSpec:
    """An external MCP server SeaStar should consume as a tool source."""

    name: str
    command: str
    args: tuple[str, ...] = ()
    env: tuple[tuple[str, str], ...] = ()

    def env_dict(self) -> dict[str, str]:
        return dict(self.env)


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
            )
        )
    return tuple(specs)


async def probe_base_url(base_url: str, *, timeout: float = PROBE_TIMEOUT_SECONDS) -> list[str] | None:
    """Return the model ids advertised at ``base_url``, or ``None`` if unreachable.

    Never raises for connectivity problems — an unreachable endpoint is a signal,
    not an error, so autodetection can move on to the next candidate.
    """

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.get(f"{base_url.rstrip('/')}/models")
            response.raise_for_status()
            payload = response.json()
    except (httpx.HTTPError, ValueError):
        return None
    models = [str(item["id"]) for item in payload.get("data", ()) if item.get("id")]
    return models or None


async def detect_runtime() -> tuple[str, str, str]:
    """Probe known local runtimes and return ``(name, base_url, model)``.

    Raises :class:`ConfigError` when nothing answers — an unconfigured machine
    should be told to start a runtime, not handed a silent fallback.
    """

    for name, base_url in KNOWN_RUNTIMES:
        models = await probe_base_url(base_url)
        if models:
            return name, base_url, models[0]
    probed = ", ".join(url for _, url in KNOWN_RUNTIMES)
    raise ConfigError(
        "No local inference server answered. Start Ollama, LM Studio, llama.cpp, "
        f"MLX, vLLM or Unsloth Studio, or set [inference].base_url in {CONFIG_FILENAME}. "
        f"Probed: {probed}"
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


def detect_vault(home: Path | None = None) -> Path | None:
    """Find the user's Obsidian vault from Obsidian's own config, or ``None``.

    Obsidian records every vault it knows in ``obsidian.json``; the entry flagged
    ``open`` is the one the user last used. Reading it means SeaStar can be truly
    zero-config for anyone who already has Obsidian installed.
    """

    base = (home or Path.home()).expanduser()
    for candidate in _obsidian_config_paths(base):
        try:
            data = json.loads(candidate.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
        vaults = data.get("vaults")
        if not isinstance(vaults, dict):
            continue
        entries = [
            entry
            for entry in vaults.values()
            if isinstance(entry, dict) and entry.get("path")
        ]
        if not entries:
            continue
        opened = [entry for entry in entries if entry.get("open")]
        entries = opened or entries
        entries.sort(key=lambda entry: entry.get("ts", 0), reverse=True)
        path = Path(str(entries[0]["path"])).expanduser()
        if path.is_dir():
            return path.resolve()
    return None


async def load_config(path: Path | None = None, *, autodetect: bool = True) -> Config:
    """Resolve a complete :class:`Config`, failing loud on anything missing."""

    data: dict = {}
    config_file = _find_config_file(path)
    if config_file is not None:
        with config_file.open("rb") as handle:
            data = tomllib.load(handle)

    vault_raw = os.environ.get("SEASTAR_VAULT") or data.get("vault")
    if vault_raw:
        vault_path = Path(str(vault_raw)).expanduser().resolve()
    else:
        detected_vault = detect_vault() if autodetect else None
        if detected_vault is None:
            raise ConfigError(
                f"No vault configured and no Obsidian vault found. Run "
                f"`seastar init --vault <path>` or set [vault] in {CONFIG_FILENAME}."
            )
        vault_path = detected_vault
    if not vault_path.is_dir():
        raise ConfigError(f"Vault path is not a directory: {vault_path}")

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
        runtime_name, base_url, detected_model = await detect_runtime()
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
        "# SeaStar configuration. Generated by `seastar init`.",
        "",
        f'vault = "{vault_path}"',
        "",
        "[inference]",
        '# Leave base_url empty to let SeaStar autodetect a local runtime on startup.',
        f'base_url = "{base_url}"' if base_url else '# base_url = "http://127.0.0.1:11434/v1"',
        f'model = "{model}"' if model else '# model = "your-model-name"',
        f'api_key = "{DEFAULT_API_KEY}"',
        "max_steps = 8",
        "temperature = 0.2",
        "",
        "# Consume other MCP servers as SeaStar tools. Uncomment to enable.",
        "# [[mcp.servers]]",
        '# name = "obsidian"',
        '# command = "npx"',
        '# args = ["-y", "obsidian-mcp", "/absolute/path/to/your/vault"]',
        "",
    ]
    destination = vault_path / CONFIG_FILENAME
    destination.write_text("\n".join(lines), encoding="utf-8")
    return destination