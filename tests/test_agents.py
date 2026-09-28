"""Osaurus agent discovery: export documents, the live store, and source order."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from sea_star.agents import (
    AgentSpec,
    candidate_agent_sources,
    detect_agents,
    read_agents,
)


@pytest.fixture(autouse=True)
def _clean_env(monkeypatch):
    monkeypatch.delenv("SEASTAR_OSAURUS_CONFIG", raising=False)


def _write(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data), encoding="utf-8")


def test_provider_splits_qualified_model():
    assert AgentSpec(name="a", model="omlx/Dirk").provider == "omlx"
    assert AgentSpec(name="a", model="foundation").provider is None
    assert AgentSpec(name="a").provider is None


def test_read_agents_export_document_keeps_order(tmp_path):
    document = tmp_path / "osaurus.json"
    _write(
        document,
        {
            "version": 1,
            "default_agent": {"name": "Orchestrator", "model": "omlx/Dirk"},
            "agents": [
                {"name": "Researcher", "model": "omlx/Dirk", "description": "digs"},
                {"name": "Writer", "model": None},
            ],
        },
    )
    specs = read_agents(document)
    assert [spec.name for spec in specs] == ["Orchestrator", "Researcher", "Writer"]
    assert specs[1].description == "digs"
    assert specs[2].model is None


def test_read_agents_live_store(tmp_path):
    _write(tmp_path / "agents" / "scribe.json", {"name": "Scribe", "model": "omlx/Dirk"})
    _write(tmp_path / "config" / "default-agent.json", {"defaultModel": "omlx/Dirk"})
    specs = read_agents(tmp_path)
    names = [spec.name for spec in specs]
    assert "Scribe" in names
    assert specs[0].model == "omlx/Dirk"


def test_nameless_live_file_falls_back_to_stem(tmp_path):
    _write(tmp_path / "agents" / "scout.json", {"model": "omlx/Dirk"})
    assert [spec.name for spec in read_agents(tmp_path)] == ["scout"]


def test_read_agents_tolerates_broken_files(tmp_path):
    agents = tmp_path / "agents"
    agents.mkdir(parents=True)
    (agents / "broken.json").write_text("{ not json", encoding="utf-8")
    assert read_agents(tmp_path) == ()


def test_read_agents_missing_source_is_empty(tmp_path):
    assert read_agents(tmp_path / "absent") == ()


def test_candidate_sources_most_specific_first(tmp_path, monkeypatch):
    monkeypatch.setenv("SEASTAR_OSAURUS_CONFIG", str(tmp_path / "pinned.json"))
    home = tmp_path / "home"
    (home / ".osaurus").mkdir(parents=True)
    sources = candidate_agent_sources(tmp_path / "vault", home=home, volumes_dir=tmp_path / "none")
    assert sources[0] == tmp_path / "pinned.json"
    assert sources[1] == tmp_path / "vault" / ".seastar" / "osaurus.json"
    assert sources[2] == home / ".osaurus"


def test_candidate_sources_scan_mounted_volumes(tmp_path):
    volume = tmp_path / "Volumes" / "RoqstorMain"
    (volume / ".osaurus").mkdir(parents=True)
    (volume / "osaurus-config.json").write_text("{}", encoding="utf-8")
    sources = candidate_agent_sources(volumes_dir=tmp_path / "Volumes")
    assert volume / ".osaurus" in sources
    assert volume / "osaurus-config.json" in sources


def test_detect_agents_first_source_wins(tmp_path):
    home = tmp_path / "home"
    _write(home / ".osaurus" / "agents" / "a.json", {"name": "Alpha"})
    second = tmp_path / "second"
    _write(second / "agents" / "b.json", {"name": "Beta"})
    found = detect_agents(home=home, volumes_dir=tmp_path / "none")
    assert [spec.name for spec in found] == ["Alpha"]


def test_detect_agents_dedupes_case_insensitively(tmp_path):
    _write(tmp_path / ".osaurus" / "agents" / "a.json", {"name": "Scout"})
    _write(tmp_path / ".osaurus" / "agents" / "b.json", {"name": "scout"})
    assert [spec.name for spec in read_agents(tmp_path / ".osaurus")] == ["Scout", "scout"]
    assert [spec.name for spec in detect_agents(home=tmp_path, volumes_dir=tmp_path / "none")] == [
        "Scout"
    ]


def test_detect_agents_empty_when_nothing_present(tmp_path):
    assert detect_agents(home=tmp_path / "none", volumes_dir=tmp_path / "none") == ()
