"""The register: one question per thing, and the identity it is remembered by."""

from __future__ import annotations

import json
import plistlib
from pathlib import Path

import pytest

from sea_star import register
from sea_star.register import (
    VERDICT_NOT_A_HARNESS,
    Candidate,
    agent_state_dirs,
    decide,
    discover,
    forget,
    known_harness_names,
    load_register,
    mcp_configs,
    save_register,
    workspace_markers,
)


@pytest.fixture
def store(tmp_path):
    """A register in a temp file, so no test touches the real one."""

    return tmp_path / "register.json"


@pytest.fixture(autouse=True)
def no_machine(monkeypatch):
    """Silence every discovery family that reads the real machine."""

    monkeypatch.setattr(register, "listening_services", lambda: ())
    monkeypatch.setattr(register, "model_like_services", lambda **kwargs: ())
    monkeypatch.setattr(register, "outbound_connections", lambda: ())
    monkeypatch.setattr(register, "mcp_configs", lambda home=None: ())
    monkeypatch.setattr(register, "agent_state_dirs", lambda home=None: ())
    monkeypatch.setattr(register, "workspace_markers", lambda workspace=None: ())
    monkeypatch.setattr(register, "_installed_apps", lambda: iter(()))


# --- the store --------------------------------------------------------------


def test_a_verdict_survives_a_round_trip(store):
    decide(
        "ai.example.app",
        name="Example",
        is_harness=True,
        bundle_id="ai.example.app",
        path="/Applications/Example.app",
        register=store,
    )

    entries = load_register(store)
    assert set(entries) == {"ai.example.app"}
    assert entries["ai.example.app"].name == "Example"
    assert entries["ai.example.app"].is_harness is True
    assert entries["ai.example.app"].decided_at  # stamped, not left blank


def test_a_dismissal_is_remembered_as_a_decision(store):
    """ "Not a harness" is an answer, not an absence of one."""

    decide("com.apple.controlcenter", name="Control Center", is_harness=False, register=store)

    entry = load_register(store)["com.apple.controlcenter"]
    assert entry.verdict == VERDICT_NOT_A_HARNESS
    assert entry.is_harness is False


def test_a_verdict_can_be_undone(store):
    decide("x", name="X", is_harness=True, register=store)
    forget("x", register=store)
    assert load_register(store) == {}


def test_a_broken_register_is_empty_and_left_alone(store):
    """A malformed preferences file must not stop the app, nor be overwritten."""

    store.write_text("{not json", encoding="utf-8")
    assert load_register(store) == {}
    # Still the person's bytes: nothing was silently destroyed to tidy up.
    assert store.read_text(encoding="utf-8") == "{not json"


def test_the_register_is_written_atomically(store):
    decide("a", name="A", is_harness=True, register=store)
    save_register(load_register(store), store)

    payload = json.loads(store.read_text(encoding="utf-8"))
    assert list(payload["entries"]) == ["a"]
    assert not store.with_suffix(".tmp").exists()


def test_known_names_carry_names_ids_and_paths(store):
    """Recognition needs every spelling, because a bundle and a register disagree."""

    decide(
        "ai.unsloth.studio",
        name="Unsloth Studio",
        is_harness=True,
        bundle_id="ai.unsloth.studio",
        path="/Applications/Unsloth.app",
        register=store,
    )
    decide("noise", name="Noise", is_harness=False, register=store)

    names = known_harness_names(load_register(store))
    assert "Unsloth Studio" in names
    assert "ai.unsloth.studio" in names
    assert "/Applications/Unsloth.app" in names
    # A dismissal is not a harness, so it must not widen recognition.
    assert "Noise" not in names


# --- discovery --------------------------------------------------------------


def test_a_decided_thing_is_never_asked_about_again(store):
    decide("ai.example.app", name="Example", is_harness=True, register=store)

    assert discover(register=load_register(store)) == ()


def test_two_families_offer_one_candidate_with_both_pieces_of_evidence(store, monkeypatch):
    """Found twice is still one question, and the person gets both reasons."""

    class Fake:
        pid = 1
        process = "python3.13"
        port = 8888
        address = "127.0.0.1"
        app_path = "/Applications/Example.app"
        app_name = "Example"
        base_url = "http://127.0.0.1:8888/v1"

    monkeypatch.setattr(register, "listening_services", lambda: (Fake(),))
    monkeypatch.setattr(register, "model_like_services", lambda **kwargs: (Fake(),))
    monkeypatch.setattr(
        register,
        "outbound_connections",
        lambda: (
            type(
                "C",
                (),
                {
                    "app_path": "/Applications/Example.app",
                    "is_local_link": False,
                    "remote_host": "93.184.216.34",
                },
            )(),
        ),
    )

    found = discover(register={})
    assert len(found) == 1
    assert found[0].evidence == (
        "serving a model on http://127.0.0.1:8888/v1",
        "connected to 1 host(s) outside this machine",
    )


def test_a_plain_installed_app_is_not_accused_of_being_a_harness(store, monkeypatch):
    """"Installed" is not evidence, and thirty-one questions is noise.

    The seed table's apps are offered; every other installed app is not. Nothing
    is hidden — it simply is not proposed on no grounds.
    """

    monkeypatch.setattr(
        register,
        "_installed_apps",
        lambda: iter(
            [
                ("com.example.browser", "Browser", "/Applications/Browser.app"),
                ("com.apple.dt.Xcode", "Xcode", "/Applications/Xcode.app"),
            ]
        ),
    )

    found = discover(register={})
    assert [candidate.name for candidate in found] == ["Xcode"]
    assert found[0].evidence == ("a harness app this build already recognises",)


def test_mcp_configs_are_found_flat_and_nested(tmp_path):
    support = tmp_path / "Library" / "Application Support"
    (support / "Flat App").mkdir(parents=True)
    (support / "Flat App" / "mcp.json").write_text("{}", encoding="utf-8")
    (support / "Nested App" / "data").mkdir(parents=True)
    (support / "Nested App" / "data" / "mcp_config.json").write_text("{}", encoding="utf-8")

    owners = {owner for owner, _ in mcp_configs(tmp_path)}
    assert owners == {"Flat App", "Nested App"}


def test_agent_state_dirs_are_found(tmp_path):
    (tmp_path / ".claude").mkdir()
    (tmp_path / ".gemini").mkdir()
    (tmp_path / "not-an-agent").mkdir()

    found = dict(agent_state_dirs(tmp_path))
    assert set(found) == {"claude", "gemini"}


def test_workspace_markers_prove_use(tmp_path):
    """The family that once caught a harness whose own bundle gave up nothing."""

    (tmp_path / ".trae").mkdir()
    (tmp_path / "AGENTS.md").write_text("", encoding="utf-8")
    (tmp_path / "unrelated.txt").write_text("", encoding="utf-8")

    names = {marker.name for marker in workspace_markers(tmp_path)}
    assert names == {".trae", "AGENTS.md"}
    # No workspace named means nothing is read at all, not a guess at a default.
    assert workspace_markers(None) == ()


# --- the vocabulary family --------------------------------------------------


def _fake_app(root: Path, name: str, payload: bytes) -> str:
    app = root / f"{name}.app"
    resources = app / "Contents" / "Resources"
    resources.mkdir(parents=True)
    (resources / "app.asar").write_bytes(payload)
    return str(app)


def test_vocabulary_raises_a_candidate_on_a_protocol_word(tmp_path, monkeypatch):
    path = _fake_app(tmp_path, "Agentic", b"... mcpServers ...")
    monkeypatch.setattr(register, "_installed_apps", lambda: iter([(None, None, path)]))

    hits = register.vocabulary_hits()
    assert [hit[0] for hit in hits] == [path]
    assert "mcpServers" in hits[0][1]


def test_brand_names_alone_do_not_raise_a_candidate(tmp_path, monkeypatch):
    """The false positive that shaped this rule: Firefox, DuckDuckGo and
    ProtonVPN all name OpenAI because they ship lists of domains. A browser is
    not a harness, so a brand name can never be the only evidence."""

    path = _fake_app(tmp_path, "Browser", b"openai anthropic claude gemini copilot")
    monkeypatch.setattr(register, "_installed_apps", lambda: iter([(None, None, path)]))

    assert register.vocabulary_hits() == ()


def test_vocabulary_evidence_names_the_words_it_saw(tmp_path, monkeypatch):
    app = tmp_path / "Named.app"
    resources = app / "Contents" / "Resources"
    resources.mkdir(parents=True)
    (resources / "app.asar").write_bytes(b"mcpServers modelcontextprotocol claude")
    monkeypatch.setattr(register, "_installed_apps", lambda: iter([(None, None, str(app))]))

    found = discover(register={}, include_vocabulary=True)
    assert len(found) == 1
    evidence = found[0].evidence[0]
    assert evidence.startswith("names ")
    assert "mcpServers" in evidence


def test_vocabulary_is_off_unless_asked(tmp_path, monkeypatch):
    """The heavy read belongs to an explicit scan, not to a cockpit poll."""

    path = _fake_app(tmp_path, "Agentic", b"mcpServers")
    monkeypatch.setattr(register, "_installed_apps", lambda: iter([(None, None, path)]))

    assert discover(register={}) == ()


def test_summarise_says_nothing_is_new_in_words(monkeypatch):
    assert register.summarise(()) == "Nothing new to ask about."
    assert (
        register.summarise([Candidate("a", "A", None, None, ("x",))])
        == "1 thing(s) on this machine have not been decided yet."
    )


def test_the_candidate_model_carries_its_evidence():
    candidate = Candidate(
        identity="ai.example.app",
        name="Example",
        bundle_id="ai.example.app",
        path="/Applications/Example.app",
        evidence=("serving a model on http://127.0.0.1:8888/v1",),
        suggested_name="Example",
    )
    assert candidate.evidence[0].startswith("serving a model")
    assert candidate.bundle_id == "ai.example.app"


# --- what may not be proposed at all ---------------------------------------

#: The founder's rule, in his words: browsers are "always discretionary", their
#: traffic says nothing about how someone uses models, and listing one buries
#: the real harnesses. Two declared roles are barred — never a name list, so a
#: browser nobody has written yet is barred too.


def _write_app(root, folder, scheme):
    app = root / f"{folder}.app"
    contents = app / "Contents"
    contents.mkdir(parents=True)
    with (contents / "Info.plist").open("wb") as handle:
        plistlib.dump(
            {
                "CFBundleIdentifier": f"test.{folder.lower().replace(' ', '-')}",
                "CFBundleURLTypes": [{"CFBundleURLSchemes": [scheme]}],
            },
            handle,
        )
    return app


def test_a_declared_web_client_is_never_proposed(tmp_path, monkeypatch):
    """A browser claims http/https; that alone bars it, whatever it connects to."""

    browser = _write_app(tmp_path, "Browser", "http")
    monkeypatch.setattr(register, "_installed_apps", lambda: iter([(None, "Browser", str(browser))]))
    monkeypatch.setattr(register, "workspace_markers", lambda workspace=None: ())

    # It is even reaching outside, which used to be reason enough on its own.
    monkeypatch.setattr(
        register,
        "outbound_connections",
        lambda: (
            type(
                "C",
                (),
                {"app_path": str(browser), "is_local_link": False, "remote_host": "1.2.3.4"},
            )(),
        ),
    )

    assert discover(register={}) == ()


def test_a_system_component_is_never_proposed(tmp_path, monkeypatch):
    """ControlCenter listens on AirPlay ports. That is the OS doing its job."""

    monkeypatch.setattr(
        register,
        "listening_services",
        lambda: (
            type(
                "S",
                (),
                {
                    "pid": 1,
                    "process": "ControlCenter",
                    "port": 5000,
                    "address": "*",
                    "app_path": "/System/Library/CoreServices/ControlCenter.app",
                    "app_name": "ControlCenter",
                    "base_url": "http://127.0.0.1:5000/v1",
                    "is_loopback": False,
                },
            )(),
        ),
    )

    assert discover(register={}) == ()


def test_traffic_alone_never_raises_a_question(tmp_path, monkeypatch):
    """The bug the founder caught: Chrome was proposed for reaching outside.

    Almost everything networked reaches outside. Traffic is a fact about
    something already worth asking about; it is not a reason to ask.
    """

    plain = tmp_path / "Plain.app"
    (plain / "Contents").mkdir(parents=True)
    with (plain / "Contents" / "Info.plist").open("wb") as handle:
        plistlib.dump({"CFBundleIdentifier": "test.plain"}, handle)

    monkeypatch.setattr(register, "outbound_connections", lambda: (
        type(
            "C",
            (),
            {"app_path": str(plain), "is_local_link": False, "remote_host": "1.2.3.4"},
        )(),
    ))

    assert discover(register={}) == ()


def test_traffic_enriches_a_question_another_family_raised(tmp_path, monkeypatch):
    """A harness already worth asking about is *told* to be reaching outside."""

    app = _write_app(tmp_path, "Studio", "studio")
    monkeypatch.setattr(register, "_installed_apps", lambda: iter([(None, "Studio", str(app))]))
    monkeypatch.setattr(
        register,
        "listening_services",
        lambda: (
            type(
                "S",
                (),
                {
                    "pid": 1,
                    "process": "python3.11",
                    "port": 8123,
                    "address": "127.0.0.1",
                    "app_path": str(app),
                    "app_name": "Studio",
                    "base_url": "http://127.0.0.1:8123/v1",
                    "is_loopback": True,
                },
            )(),
        ),
    )
    monkeypatch.setattr(register, "model_like_services", lambda **kwargs: ())
    monkeypatch.setattr(register, "outbound_connections", lambda: (
        type(
            "C",
            (),
            {"app_path": str(app), "is_local_link": False, "remote_host": "1.2.3.4"},
        )(),
    ))

    found = discover(register={})
    assert len(found) == 1
    assert "connected to 1 host(s) outside this machine" in found[0].evidence


def test_an_app_keeping_a_tool_list_is_asked_about_once(tmp_path, monkeypatch):
    """Two findings, one app, one question — the register's whole promise.

    Found by getting it wrong: Atomic Chat arrived twice, once as the app and
    once as the folder that keeps its tool list.
    """

    app = _write_app(tmp_path, "Atomic Chat", "atomic-chat")
    support = tmp_path / "Library" / "Application Support" / "Atomic Chat" / "data"
    support.mkdir(parents=True)
    (support / "mcp_config.json").write_text("{}", encoding="utf-8")

    monkeypatch.setattr(
        register, "_installed_apps", lambda: iter([("chat.atomic.app", "Atomic Chat", str(app))])
    )
    monkeypatch.setattr(
        register, "mcp_configs", lambda home=None: (("Atomic Chat", support / "mcp_config.json"),)
    )

    found = discover(register={})
    assert len(found) == 1
    assert found[0].identity == "chat.atomic.app"
    assert found[0].evidence == ("keeps a list of tools it can call (mcp_config.json)",)
