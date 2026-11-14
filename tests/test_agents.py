"""Osaurus agent discovery: export documents, the live store, and source order."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from sea_star.agents import (
    AGENT_ADAPTER,
    AGENT_MARKDOWN_ADAPTER,
    AgentSpec,
    candidate_agent_sources,
    detect_agent_instances,
    detect_agent_roster,
    detect_agents,
    placement,
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


class FakeProbe:
    """A minimal runtime double: a name and the models it lists."""

    def __init__(self, name, models):
        self.name = name
        self.models = list(models)


def _spec(name, model):
    return AgentSpec(name=name, model=model, description="")


def test_placement_names_the_serving_endpoint():
    """Case one: the model is on offer, so the sentence says where it is."""

    probes = [FakeProbe("omlx", ["KAT-Coder", "Qwen3"])]
    text = placement(_spec("Patchdog", "KAT-Coder"), probes)
    assert text == "Runs on KAT-Coder — served by omlx."


def test_placement_distinguishes_up_but_not_serving():
    """Case two is the live trap: the provider is up and the model is not on it.

    On the real machine this is Patchdog's state, and flattening it into "not
    offered anywhere" would be a lie in the other direction.
    """

    probes = [FakeProbe("omlx", ["Qwen3"])]
    text = placement(_spec("Patchdog", "omlx/KAT-Coder"), probes)
    assert text == "Runs on omlx/KAT-Coder — omlx is up, but not serving it."


def test_placement_says_when_nowhere_offers_it():
    probes = [FakeProbe("omlx", ["Qwen3"])]
    text = placement(_spec("Lono", "OsaurusAI/Raptor"), probes)
    assert text == "Runs on OsaurusAI/Raptor — not offered by any running endpoint."


def test_placement_handles_an_agent_with_no_model():
    text = placement(_spec("Drifter", None), [])
    assert text == "Rides whatever the endpoint is serving."


# --- Agent files as a shape -----------------------------------------------------
#
# The failure these exist to prevent: reading only a harness's own store made the
# cockpit report "no roster found" while the person had a dozen agents written as
# Markdown files. One cupboard was checked and presented as the whole house.


def _write_agent(path: Path, name: str, model: str | None = None, description: str = "") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = ["---", f"name: {name}"]
    if description:
        lines.append(f"description: {description}")
    if model:
        lines.append(f"model: {model}")
    lines += ["tools: Read, Grep", "---", "", "You are that agent.", ""]
    path.write_text("\n".join(lines), encoding="utf-8")


def test_an_agent_written_as_a_file_is_found(tmp_path):
    """The whole point: no product named anywhere, only a file shape."""

    _write_agent(tmp_path / ".claude" / "agents" / "lono.md", "Lono", model="mlx/mimo")
    roster = detect_agent_roster(home=tmp_path, volumes_dir=tmp_path / "none")

    assert [spec.name for spec in roster.specs] == ["Lono"]
    assert roster.specs[0].model == "mlx/mimo"
    assert AGENT_MARKDOWN_ADAPTER in (roster.source or "")


def test_a_harness_nobody_has_heard_of_is_read_by_its_layout(tmp_path):
    """A dot-directory nobody here knows the name of, holding an ``agents/``
    folder. The directory name is the convention; the tool is not consulted."""

    _write_agent(tmp_path / ".vibeweaver" / "agents" / "shipper.md", "Shipper")
    roster = detect_agent_roster(home=tmp_path, volumes_dir=tmp_path / "none")

    assert [spec.name for spec in roster.specs] == ["Shipper"]


def test_agents_belonging_to_the_workspace_a_harness_is_pointed_at_are_found(tmp_path):
    """Project scope: where the harness is pointed decides which agents it has."""

    workspace = tmp_path / "project"
    _write_agent(workspace / ".claude" / "agents" / "reviewer.md", "Reviewer")
    roster = detect_agent_roster(
        vault_path=None, home=tmp_path / "home", workspace=workspace, volumes_dir=tmp_path / "none"
    )

    assert [spec.name for spec in roster.specs] == ["Reviewer"]


def test_a_populated_store_cannot_hide_the_agent_files(tmp_path):
    """Union, not first-match-wins. Returning the first non-empty source reported a
    roster that existed and silently omitted the rest — the same lie as reporting
    none, and harder to notice because the row looked populated."""

    _write(tmp_path / ".osaurus" / "agents" / "store.json", {"name": "Osaurus One", "model": "a/b"})
    _write_agent(tmp_path / ".claude" / "agents" / "lono.md", "Lono")

    roster = detect_agent_roster(home=tmp_path, volumes_dir=tmp_path / "none")
    names = sorted(spec.name for spec in roster.specs)

    assert names == ["Lono", "Osaurus One"]
    assert AGENT_ADAPTER in (roster.source or "")
    assert AGENT_MARKDOWN_ADAPTER in (roster.source or "")


def test_a_readme_in_an_agents_folder_is_not_an_agent(tmp_path):
    """A file with no readable name is passed over, not half-read into a phantom."""

    agents = tmp_path / ".claude" / "agents"
    agents.mkdir(parents=True)
    (agents / "README.md").write_text("# Agents\nPut them here.\n", encoding="utf-8")
    (agents / "notes.md").write_text("---\ndescription: nameless\n---\nbody\n", encoding="utf-8")

    roster = detect_agent_roster(home=tmp_path, volumes_dir=tmp_path / "none")
    assert roster.specs == ()


def test_an_unterminated_header_yields_no_agent(tmp_path):
    """A header that never closes is not a header. Reading past it would invent
    fields from a Markdown document."""

    agents = tmp_path / ".claude" / "agents"
    agents.mkdir(parents=True)
    (agents / "broken.md").write_text("---\nname: Ghost\n\n# just a document\n", encoding="utf-8")

    roster = detect_agent_roster(home=tmp_path, volumes_dir=tmp_path / "none")
    assert roster.specs == ()


def test_a_quoted_value_is_read_cleanly(tmp_path):
    """YAML permits quotes; the value a person sees should not carry them."""

    _write_agent(tmp_path / ".claude" / "agents" / "q.md", "Quoted", model="'mlx/mimo'")
    roster = detect_agent_roster(home=tmp_path, volumes_dir=tmp_path / "none")

    assert roster.specs[0].model == "mlx/mimo"


def test_two_agents_with_one_name_are_reported_once(tmp_path):
    """Project and personal scope may both define "Lono"; that is one persona, and
    drawing it twice would read as two agents."""

    _write_agent(tmp_path / ".claude" / "agents" / "lono.md", "Lono", model="mlx/mimo")
    home = tmp_path / "home"
    _write_agent(home / ".claude" / "agents" / "lono.md", "Lono", model="mlx/mimo")

    roster = detect_agent_roster(home=home, volumes_dir=tmp_path / "none")
    assert [spec.name for spec in roster.specs] == ["Lono"]


# --- Agent instances: one agent, however many processes it is made of -----------


def _table(*rows: tuple[int, int, str]) -> dict[int, tuple[int, str]]:
    return {pid: (ppid, command) for pid, ppid, command in rows}


def test_a_dozen_processes_is_one_agent(tmp_path):
    """The desktop app is an app, a CLI, helpers and renderers. Counting processes
    would call one conversation eight agents."""

    app = "/Applications/OpenCode.app/Contents/MacOS/OpenCode"
    helper = "/Applications/OpenCode.app/Contents/Frameworks/OpenCode Helper.app/Contents/MacOS/OpenCode Helper"
    table = _table(
        (100, 1, app),
        (101, 100, helper),
        (102, 100, helper),
        (103, 100, "/Applications/OpenCode.app/Contents/Frameworks/OpenCode Helper (Renderer).app/Contents/MacOS/X"),
    )
    found = detect_agent_instances(
        table=table, agent_pids=(100, 101, 102, 103), products={100: "OpenCode"}
    )

    assert [i.pid for i in found] == [100]
    assert found[0].product == "OpenCode"


def test_a_cli_beside_an_app_is_its_own_agent(tmp_path):
    """Two instances the person is talking to are two agents. Collapsing them would
    hide the second conversation entirely."""

    table = _table(
        (100, 1, "/Applications/OpenCode.app/Contents/MacOS/OpenCode"),
        (200, 1, "/Users/lono/.opencode/bin/opencode-cli"),
    )
    found = detect_agent_instances(table=table, agent_pids=(100, 200))

    assert [i.pid for i in found] == [100, 200]


def test_an_unnamed_running_agent_is_still_an_agent(tmp_path):
    """No persona file, no name — and still reported. Declining to show work in
    progress because no definition exists is the blindness the name-less CLI had."""

    table = _table((300, 1, "/usr/local/bin/some-agent-nobody-predicted"))
    found = detect_agent_instances(table=table, agent_pids=(300,))

    assert [i.product for i in found] == ["some-agent-nobody-predicted"]


def test_a_pure_model_server_is_flagged_rather_than_dismissed(tmp_path):
    """An inference endpoint is a real thing on the machine. Hiding it would be its
    own lie; calling it an agent would be a category error. It is reported, with the
    fact that it only serves."""

    table = _table((400, 1, "/usr/local/bin/python3.11"))
    found = detect_agent_instances(table=table, agent_pids=(400,), runtime_pids=(400,))

    assert found[0].serves_models is True
    assert found[0].is_attached is False


def test_a_chat_app_that_both_drives_and_serves_is_not_mislabelled(tmp_path):
    """Atomic Chat hosts the model server it also drives Sea-Star through. Filing it
    as either one thing loses half the truth — the error that made the cockpit
    unreadable once already."""

    table = _table((500, 1, "/Applications/Atomic Chat.app/Contents/MacOS/Atomic-Chat"))
    found = detect_agent_instances(
        table=table, agent_pids=(500,), attached_pids=(500,), runtime_pids=(500,)
    )

    assert found[0].is_attached is True
    assert found[0].serves_models is True
