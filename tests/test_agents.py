"""Osaurus agent discovery: export documents, the live store, and source order."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from sea_star.agents import (
    AGENT_ADAPTER,
    AgentSpec,
    candidate_agent_sources,
    detect_agent_roster,
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


def test_default_agent_is_read_by_display_name(tmp_path):
    """The orchestrator must not vanish because the file spells it differently.

    Osaurus writes the boot persona to ``config/default-agent.json`` under
    ``displayName``, while an export document uses ``name``. Reading only the
    export's spelling dropped the orchestrator entirely, so the cockpit showed a
    roster with no default agent in it — a real persona the harness plainly
    knows about, reported as absent.
    """
    _write(
        tmp_path / "config" / "default-agent.json",
        {"displayName": "Lono", "defaultModel": "peculiar-ragdoll/Dirk"},
    )
    specs = read_agents(tmp_path)
    assert [spec.name for spec in specs] == ["Lono"]
    assert specs[0].model == "peculiar-ragdoll/Dirk"


def test_orchestrator_leads_the_live_store(tmp_path):
    """The default agent comes first, matching ``osaurus config export``."""
    _write(tmp_path / "agents" / "a.json", {"name": "Patchdog", "defaultModel": "omlx/KAT"})
    _write(tmp_path / "config" / "default-agent.json", {"displayName": "Lono", "defaultModel": "omlx/Dirk"})
    assert [spec.name for spec in read_agents(tmp_path)] == ["Lono", "Patchdog"]


def test_display_name_does_not_invent_nameless_agents(tmp_path):
    """A default-agent file with no usable name is still skipped.

    The per-agent directory is deliberately different: it falls back to the file
    stem, so those files always carry a name. The default-agent file has no stem
    worth showing a person, so without a real name it stays out of the roster
    rather than appearing as something like ``default-agent``.
    """
    _write(tmp_path / "config" / "default-agent.json", {"defaultModel": "omlx/Dirk"})
    assert read_agents(tmp_path) == ()


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


def test_roster_names_the_adapter_it_came_from(tmp_path):
    """A roster belongs to the app it was read from, not to the machine.

    The cockpit has to be able to say *whose* personas these are, so the roster
    carries the adapter that produced it. Presenting one app's agents as a
    global roster would be the same overclaim in a new place.
    """
    _write(tmp_path / ".osaurus" / "agents" / "a.json", {"name": "Scout"})
    roster = detect_agent_roster(home=tmp_path, volumes_dir=tmp_path / "none")
    assert roster.source == AGENT_ADAPTER
    assert [spec.name for spec in roster.specs] == ["Scout"]
    assert roster.path == tmp_path / ".osaurus"
    assert not roster.is_empty


def test_roster_with_nothing_found_is_absent_not_empty(tmp_path):
    """"No roster found" and "a roster that happens to be empty" differ.

    The first is a fact the app can state; the second would mean a source
    answered with no agents. Only the first is reachable today, and a ``None``
    source is what tells them apart.
    """
    roster = detect_agent_roster(home=tmp_path / "none", volumes_dir=tmp_path / "none")
    assert roster.source is None
    assert roster.path is None
    assert roster.specs == ()
    assert roster.is_empty


def test_detect_agents_still_returns_just_the_specs(tmp_path):
    """The old tuple-returning entry point keeps working for its callers."""
    _write(tmp_path / ".osaurus" / "agents" / "a.json", {"name": "Scout"})
    assert detect_agents(home=tmp_path, volumes_dir=tmp_path / "none") == (
        AgentSpec(name="Scout", model=None, description=""),
    )
