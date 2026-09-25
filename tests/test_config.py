"""Config resolution: file reading, env overrides, and loud failure."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from sea_star.config import (
    VAULT_SOURCE_CONFIG,
    VAULT_SOURCE_ENV,
    VAULT_SOURCE_OBSIDIAN,
    ConfigError,
    MCPServerSpec,
    RuntimeProbe,
    detect_runtime,
    detect_vault,
    detect_vault_candidates,
    load_config,
    probe_runtimes,
    resolve_vault,
    write_default_config,
)


@pytest.fixture(autouse=True)
def _clean_env(monkeypatch):
    for key in ("SEASTAR_VAULT", "SEASTAR_BASE_URL", "SEASTAR_MODEL", "SEASTAR_API_KEY", "SEASTAR_RUNTIME"):
        monkeypatch.delenv(key, raising=False)


def _write_obsidian(home: Path, vaults: dict) -> None:
    obsidian = home / "Library" / "Application Support" / "obsidian"
    obsidian.mkdir(parents=True, exist_ok=True)
    (obsidian / "obsidian.json").write_text(json.dumps({"vaults": vaults}), encoding="utf-8")


async def test_init_then_load_without_network(tmp_path):
    write_default_config(tmp_path, model="test-model", base_url="http://127.0.0.1:9999/v1")
    config = await load_config(tmp_path / "seastar.toml", autodetect=False)
    assert config.vault_path == tmp_path.resolve()
    assert config.model == "test-model"
    assert config.base_url == "http://127.0.0.1:9999/v1"


async def test_missing_vault_fails_loud(tmp_path):
    with pytest.raises(ConfigError):
        await load_config(tmp_path / "absent.toml", autodetect=False)


async def test_env_overrides_file(tmp_path, monkeypatch):
    write_default_config(tmp_path, model="fromfile", base_url="http://127.0.0.1:9999/v1")
    monkeypatch.setenv("SEASTAR_MODEL", "fromenv")
    config = await load_config(tmp_path / "seastar.toml", autodetect=False)
    assert config.model == "fromenv"


async def test_probe_runtimes_reports_every_live_server(monkeypatch):
    async def fake(base_url, *, timeout=1.5):
        return {
            "http://127.0.0.1:1337/v1": ["foundation"],
            "http://127.0.0.1:8000/v1": ["mlx-community/Qwen3"],
        }.get(base_url)

    monkeypatch.setattr("sea_star.config.probe_base_url", fake)
    probes = await probe_runtimes()
    assert [(probe.name, probe.base_url, probe.model) for probe in probes] == [
        ("osaurus", "http://127.0.0.1:1337/v1", "foundation"),
        ("omlx", "http://127.0.0.1:8000/v1", "mlx-community/Qwen3"),
    ]


async def test_probe_runtimes_keeps_known_order(monkeypatch):
    async def fake(base_url, *, timeout=1.5):
        return ["m"] if base_url == "http://127.0.0.1:11434/v1" else None

    monkeypatch.setattr("sea_star.config.probe_base_url", fake)
    assert [probe.name for probe in await probe_runtimes()] == ["ollama"]


async def test_probe_runtimes_dedupes_a_shared_port(monkeypatch):
    async def fake(base_url, *, timeout=1.5):
        return ["m"] if base_url == "http://127.0.0.1:8000/v1" else None

    monkeypatch.setattr("sea_star.config.probe_base_url", fake)
    assert [probe.name for probe in await probe_runtimes()] == ["omlx"]


async def test_detect_runtime_reuses_a_survey_without_reprobe(monkeypatch):
    async def exploding(*args, **kwargs):
        raise AssertionError("detect_runtime should not probe when given probes")

    monkeypatch.setattr("sea_star.config.probe_base_url", exploding)
    probes = (RuntimeProbe("omlx", "http://127.0.0.1:8000/v1", ("m",)),)
    assert await detect_runtime(probes=probes) == ("omlx", "http://127.0.0.1:8000/v1", "m")


async def test_detect_runtime_fails_loud_when_nothing_answers(monkeypatch):
    async def fake(base_url, *, timeout=1.5):
        return None

    monkeypatch.setattr("sea_star.config.probe_base_url", fake)
    with pytest.raises(ConfigError):
        await detect_runtime()


async def test_servers_are_parsed(tmp_path):
    (tmp_path / "seastar.toml").write_text(
        "\n".join(
            [
                f'vault = "{tmp_path}"',
                "[inference]",
                'base_url = "http://127.0.0.1:9999/v1"',
                'model = "m"',
                "[[mcp.servers]]",
                'name = "obsidian"',
                'command = "npx"',
                'args = ["-y", "obsidian-mcp"]',
                '[mcp.servers.env]',
                'VAULT = "/tmp/v"',
            ]
        ),
        encoding="utf-8",
    )
    config = await load_config(tmp_path / "seastar.toml", autodetect=False)
    assert len(config.servers) == 1
    spec = config.servers[0]
    assert spec.name == "obsidian"
    assert spec.command == "npx"
    assert spec.args == ("-y", "obsidian-mcp")
    assert spec.env_dict()["VAULT"] == "/tmp/v"


def test_detect_vault_prefers_open_vault(tmp_path):
    open_vault = tmp_path / "MyVault"
    other_vault = tmp_path / "Other"
    open_vault.mkdir()
    other_vault.mkdir()
    obsidian = tmp_path / "Library" / "Application Support" / "obsidian"
    obsidian.mkdir(parents=True)
    (obsidian / "obsidian.json").write_text(
        json.dumps(
            {
                "vaults": {
                    "a": {"path": str(other_vault), "ts": 99999999},
                    "b": {"path": str(open_vault), "ts": 1, "open": True},
                }
            }
        ),
        encoding="utf-8",
    )
    assert detect_vault(home=tmp_path) == open_vault.resolve()


def test_detect_vault_returns_none_without_obsidian(tmp_path):
    assert detect_vault(home=tmp_path) is None


def test_candidates_order_open_first_then_most_recent(tmp_path):
    open_vault = tmp_path / "Open"
    recent = tmp_path / "Recent"
    old = tmp_path / "Old"
    for path in (open_vault, recent, old):
        path.mkdir()
    _write_obsidian(
        tmp_path,
        {
            "a": {"path": str(old), "ts": 1},
            "b": {"path": str(recent), "ts": 999},
            "c": {"path": str(open_vault), "ts": 2, "open": True},
        },
    )
    assert detect_vault_candidates(home=tmp_path) == (
        open_vault.resolve(),
        recent.resolve(),
        old.resolve(),
    )


def test_candidates_skip_missing_directories(tmp_path):
    present = tmp_path / "Present"
    present.mkdir()
    _write_obsidian(
        tmp_path,
        {
            "a": {"path": str(tmp_path / "Gone"), "ts": 5},
            "b": {"path": str(present), "ts": 1},
        },
    )
    assert detect_vault_candidates(home=tmp_path) == (present.resolve(),)


def test_resolve_vault_env_wins(tmp_path, monkeypatch):
    monkeypatch.setenv("SEASTAR_VAULT", str(tmp_path))
    path, source = resolve_vault({"vault": "/nope"}, home=tmp_path)
    assert path == tmp_path.resolve()
    assert source == VAULT_SOURCE_ENV


def test_resolve_vault_from_toml(tmp_path):
    path, source = resolve_vault({"vault": str(tmp_path)}, autodetect=False)
    assert path == tmp_path.resolve()
    assert source == VAULT_SOURCE_CONFIG


def test_resolve_vault_autodetects_obsidian(tmp_path):
    vault = tmp_path / "V"
    vault.mkdir()
    _write_obsidian(tmp_path, {"a": {"path": str(vault), "ts": 1, "open": True}})
    path, source = resolve_vault({}, home=tmp_path)
    assert path == vault.resolve()
    assert source == VAULT_SOURCE_OBSIDIAN


def test_resolve_vault_fails_loud(tmp_path):
    with pytest.raises(ConfigError):
        resolve_vault({}, autodetect=False)
    with pytest.raises(ConfigError):
        resolve_vault({}, home=tmp_path)


def test_allows_default_exposes_everything():
    assert MCPServerSpec(name="s", command="c").allows("anything")


def test_allows_allowlist_limits_surface():
    spec = MCPServerSpec(name="s", command="c", include=("search", "read"))
    assert spec.allows("search")
    assert not spec.allows("write")


def test_allows_denylist_removes_tools():
    spec = MCPServerSpec(name="s", command="c", exclude=("delete",))
    assert spec.allows("search")
    assert not spec.allows("delete")


def test_allows_exclude_beats_include():
    spec = MCPServerSpec(name="s", command="c", include=("search", "delete"), exclude=("delete",))
    assert spec.allows("search")
    assert not spec.allows("delete")