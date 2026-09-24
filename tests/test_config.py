"""Config resolution: file reading, env overrides, and loud failure."""

from __future__ import annotations

import json

import pytest

from sea_star.config import ConfigError, detect_vault, load_config, write_default_config


@pytest.fixture(autouse=True)
def _clean_env(monkeypatch):
    for key in ("SEASTAR_VAULT", "SEASTAR_BASE_URL", "SEASTAR_MODEL", "SEASTAR_API_KEY", "SEASTAR_RUNTIME"):
        monkeypatch.delenv(key, raising=False)


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