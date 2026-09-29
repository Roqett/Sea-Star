"""The `doctor --json` bridge: one JSON object, always, in the §6 shape."""

from __future__ import annotations

import json

import pytest
from typer.testing import CliRunner

from sea_star import __version__
from sea_star.agents import AGENT_ADAPTER, AgentRoster, AgentSpec
from sea_star.cli import app
from sea_star.config import RuntimeProbe
from sea_star.harnesses import HarnessSpec

runner = CliRunner()


@pytest.fixture(autouse=True)
def _clean_env(monkeypatch):
    for key in ("SEASTAR_VAULT", "SEASTAR_BASE_URL", "SEASTAR_MODEL", "SEASTAR_API_KEY", "SEASTAR_RUNTIME"):
        monkeypatch.delenv(key, raising=False)
    # Latent-harness discovery reads the real /Applications; keep every bridge
    # test hermetic unless a test opts back in by re-patching.
    monkeypatch.setattr("sea_star.cli.detect_latent_harnesses", lambda **kwargs: ())
    # Agent discovery reads the real ~/.osaurus; same reasoning.
    monkeypatch.setattr(
        "sea_star.cli.detect_agent_roster",
        lambda *args, **kwargs: AgentRoster(specs=(), source=None, path=None),
    )


def _async_return(value):
    async def _inner(*args, **kwargs):
        return value

    return _inner


def _write_vault(tmp_path):
    vault = tmp_path / "Vault"
    vault.mkdir()
    (vault / "note.md").write_text("hello", encoding="utf-8")
    (tmp_path / "seastar.toml").write_text(
        "\n".join(
            [
                f'vault = "{vault}"',
                "[inference]",
                'base_url = "http://127.0.0.1:9999/v1"',
                'model = "test-model"',
                "[[mcp.servers]]",
                'name = "obsidian"',
                'command = "npx"',
                'include = ["search"]',
                'exclude = ["delete"]',
            ]
        ),
        encoding="utf-8",
    )
    return vault


def test_doctor_json_emits_the_bridge_shape(tmp_path, monkeypatch):
    vault = _write_vault(tmp_path)
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr("sea_star.cli.probe_base_url", _async_return(["test-model"]))
    monkeypatch.setattr("sea_star.cli.probe_runtimes", _async_return(()))
    monkeypatch.setattr("sea_star.cli.detect_vault_candidates", lambda home=None: ())

    result = runner.invoke(app, ["doctor", "--json"])

    assert result.exit_code == 0
    report = json.loads(result.stdout)
    assert report["schema_version"] == 1
    assert report["version"] == __version__
    assert report["ready"] is True
    assert report["vault"] == {
        "path": str(vault.resolve()),
        "source": "toml",
        "note_count": 1,
        "candidates": [],
    }
    assert report["runtime"] == "custom"
    assert report["model"] == "test-model"
    assert report["models"] == ["test-model"]
    assert report["runtimes"] == []
    assert report["latent_harnesses"] == []
    assert report["server"] == {"state": "running"}
    assert report["servers"] == [
        {"name": "obsidian", "command": "npx", "include": ["search"], "exclude": ["delete"]}
    ]


def test_doctor_json_reports_every_running_harness(tmp_path, monkeypatch):
    _write_vault(tmp_path)
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr("sea_star.cli.probe_base_url", _async_return(["test-model"]))
    monkeypatch.setattr(
        "sea_star.cli.probe_runtimes",
        _async_return(
            (
                RuntimeProbe("osaurus", "http://127.0.0.1:1337/v1", ("foundation",)),
                RuntimeProbe("omlx", "http://127.0.0.1:8000/v1", ("mlx-community/Qwen3",)),
            )
        ),
    )
    monkeypatch.setattr("sea_star.cli.detect_vault_candidates", lambda home=None: ())

    result = runner.invoke(app, ["doctor", "--json"])

    assert result.exit_code == 0
    report = json.loads(result.stdout)
    assert report["runtimes"] == [
        {
            "name": "osaurus",
            "base_url": "http://127.0.0.1:1337/v1",
            "model": "foundation",
            "models": ["foundation"],
        },
        {
            "name": "omlx",
            "base_url": "http://127.0.0.1:8000/v1",
            "model": "mlx-community/Qwen3",
            "models": ["mlx-community/Qwen3"],
        },
    ]


def test_doctor_json_reports_latent_harnesses(tmp_path, monkeypatch):
    _write_vault(tmp_path)
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr("sea_star.cli.probe_base_url", _async_return(["test-model"]))
    monkeypatch.setattr("sea_star.cli.probe_runtimes", _async_return(()))
    monkeypatch.setattr("sea_star.cli.detect_vault_candidates", lambda home=None: ())
    monkeypatch.setattr(
        "sea_star.cli.detect_latent_harnesses",
        lambda **kwargs: (
            HarnessSpec(
                name="Xcode", bundle_id="com.apple.dt.Xcode", path="/Applications/Xcode.app"
            ),
            HarnessSpec(
                name="Goose", bundle_id="com.electron.goose", path="/Applications/Goose.app"
            ),
        ),
    )

    result = runner.invoke(app, ["doctor", "--json"])

    assert result.exit_code == 0
    report = json.loads(result.stdout)
    assert report["latent_harnesses"] == [
        {"name": "Xcode", "bundle_id": "com.apple.dt.Xcode", "path": "/Applications/Xcode.app"},
        {"name": "Goose", "bundle_id": "com.electron.goose", "path": "/Applications/Goose.app"},
    ]


def test_doctor_json_reports_agent_scope_with_the_roster(tmp_path, monkeypatch):
    """A roster must say whose roster it is.

    The cockpit shows an Agent row. Without ``agent_source`` the app would have
    to present one adapter's personas as though they were the machine's, which
    is the overclaim the foundation forbids. So the scope travels with the list.
    """
    _write_vault(tmp_path)
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr("sea_star.cli.probe_base_url", _async_return(["test-model"]))
    monkeypatch.setattr("sea_star.cli.probe_runtimes", _async_return(()))
    monkeypatch.setattr("sea_star.cli.detect_vault_candidates", lambda home=None: ())
    monkeypatch.setattr(
        "sea_star.cli.detect_agent_roster",
        lambda *args, **kwargs: AgentRoster(
            specs=(AgentSpec(name="Scout", model="omlx/Dirk", description="digs"),),
            source=AGENT_ADAPTER,
            path=tmp_path / ".osaurus",
        ),
    )

    result = runner.invoke(app, ["doctor", "--json"])

    assert result.exit_code == 0
    report = json.loads(result.stdout)
    assert report["agents"] == [
        {"name": "Scout", "model": "omlx/Dirk", "description": "digs"}
    ]
    assert report["agent_source"] == AGENT_ADAPTER


def test_doctor_json_reports_no_agent_source_when_there_is_no_roster(tmp_path, monkeypatch):
    """An absent roster and an empty one are different facts, and the key says which.

    ``null`` here means "nothing was found" — not "a source answered with no
    agents" — so the app can say the difference out loud rather than showing a
    blank row.
    """
    _write_vault(tmp_path)
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr("sea_star.cli.probe_base_url", _async_return(["test-model"]))
    monkeypatch.setattr("sea_star.cli.probe_runtimes", _async_return(()))
    monkeypatch.setattr("sea_star.cli.detect_vault_candidates", lambda home=None: ())

    result = runner.invoke(app, ["doctor", "--json"])

    assert result.exit_code == 0
    report = json.loads(result.stdout)
    assert report["agents"] == []
    assert report["agent_source"] is None


def test_doctor_json_fails_loud_with_one_object(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr("sea_star.config.detect_vault", lambda home=None: None)

    result = runner.invoke(app, ["doctor", "--json"])

    assert result.exit_code == 1
    report = json.loads(result.stdout)
    assert report["ready"] is False
    assert report["error"]


def test_doctor_human_output_is_the_default(tmp_path, monkeypatch):
    _write_vault(tmp_path)
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr("sea_star.cli.probe_base_url", _async_return(["test-model"]))
    monkeypatch.setattr("sea_star.cli.probe_runtimes", _async_return(()))
    monkeypatch.setattr("sea_star.cli.detect_vault_candidates", lambda home=None: ())

    result = runner.invoke(app, ["doctor"])

    assert result.exit_code == 0
    assert "Ready." in result.stdout
    assert not result.stdout.lstrip().startswith("{")
