"""Reconnaissance: the read is honest, attributed, and never runs itself."""

from __future__ import annotations

import plistlib

import pytest

from sea_star import recon
from sea_star.recon import (
    ListeningService,
    _split_address,
    listening_services,
    model_like_services,
    outbound_connections,
    owning_app,
    process_table,
)

# --- canned command output, so no test depends on what is running ------------

#: A helper holding a model server's port, three rungs below the app that
#: launched it — the shape that makes attribution worth doing at all.
PS = """\
  100     1 /Applications/Some Studio.app/Contents/MacOS/studio
  200   100 /Applications/Some Studio.app/Contents/Helpers/server
  300   200 /usr/bin/python3.11 -m server --port 8123
  400     1 /usr/bin/python3 -c serve
  500     1 /Applications/Other.app/Contents/MacOS/other
"""

LISTEN = """\
p300
cpython3.11
n127.0.0.1:8123
p400
cpython3
n127.0.0.1:9999
p500
cother
n*:7000
p300
cpython3.11
n127.0.0.1:8123
"""

ESTABLISHED = """\
p300
cpython3.11
n127.0.0.1:8123->127.0.0.1:55001
p500
cother
n192.168.1.5:55002->93.184.216.34:443
p500
cother
n192.168.1.5:55002->93.184.216.34:443
"""


@pytest.fixture
def machine(monkeypatch):
    """A fake machine: `ps` and `lsof` answer from the canned tables above."""

    def fake_run(command: list[str], timeout: int = 10) -> str:
        joined = " ".join(command)
        if command and command[0] == "ps":
            return PS
        if "LISTEN" in joined:
            return LISTEN
        if "ESTABLISHED" in joined:
            return ESTABLISHED
        return ""

    monkeypatch.setattr(recon, "_run", fake_run)
    return fake_run


# --- address parsing --------------------------------------------------------


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("127.0.0.1:8009", ("127.0.0.1", 8009)),
        ("*:7000", ("*", 7000)),
        ("[::1]:8009", ("::1", 8009)),
        ("[2406:2d40::bc]:443", ("2406:2d40::bc", 443)),
        ("not-an-address", None),
    ],
)
def test_split_address_reads_lsof_forms(text, expected):
    assert _split_address(text) == expected


# --- attribution -----------------------------------------------------------


def test_attribution_walks_the_tree_to_the_app(machine):
    table = process_table()
    # The port is held by a python a person has never heard of, three rungs
    # below the app they double-clicked.
    # The name comes from the bundle's own Info.plist when it can be read, and
    # from the folder name when it cannot — never from a list of known apps.
    assert owning_app(300, table) == ("/Applications/Some Studio.app", "Some Studio")


def test_a_bare_process_is_owned_by_no_app(machine):
    """An honest absence: not every process belongs to an app."""

    table = process_table()
    assert owning_app(400, table) == (None, None)


# --- listening services ----------------------------------------------------


def test_listening_services_are_attributed_and_deduplicated(machine):
    services = {service.port: service for service in listening_services()}

    assert set(services) == {8123, 9999, 7000}
    assert services[8123].app_name == "Some Studio"
    assert services[8123].is_loopback is True
    assert services[8123].base_url == "http://127.0.0.1:8123/v1"
    # `*` is offered to the network, which is a different fact from loopback.
    assert services[7000].is_loopback is False


# --- what counts as inference ---------------------------------------------


def test_runtime_vocabulary_finds_a_model_server(machine):
    """`python3.11 -m server` is found by the app above it, not by its own name."""

    found = {service.port for service in model_like_services()}
    assert found == set()


def test_known_app_finds_an_endpoint_that_names_no_runtime(machine):
    """A port naming no runtime is still inference when its app is agreed.

    This is the layering that lets the register do the work a name list cannot:
    the vocabulary stays general, and the person's own answers fill the rest.
    """

    found = {service.port for service in model_like_services(known_apps=["some studio"])}
    assert found == {8123}


def test_runtime_vocabulary_alone_identifies_a_model_server():
    """The generalising half: a runtime family word needs no agreement at all."""

    llama = ListeningService(
        pid=1, process="llama-server", port=8080, address="127.0.0.1",
        app_path="/Applications/Unknown.app", app_name="Unknown",
    )
    # An app nobody has heard of, running a runtime everybody has.
    assert recon._speaks_runtime_vocabulary(llama) is True

    silent = ListeningService(
        pid=2, process="python3", port=8081, address="127.0.0.1",
        app_path="/Applications/Unknown.app", app_name="Unknown",
    )
    assert recon._speaks_runtime_vocabulary(silent) is False


def test_the_register_matches_by_identity_not_by_label(tmp_path, monkeypatch):
    """The bug this test exists for: the register said "Unsloth Studio" while the
    bundle called itself "Unsloth", and a real endpoint was silently lost.

    The app folder and the app's own display name are two different strings for
    the same thing, so a register entry may be either — or the path. All three
    have to be enough.
    """

    app = tmp_path / "Unsloth Studio.app"
    contents = app / "Contents"
    contents.mkdir(parents=True)
    with (contents / "Info.plist").open("wb") as handle:
        plistlib.dump(
            {"CFBundleIdentifier": "ai.unsloth.studio", "CFBundleName": "Unsloth"}, handle
        )
    ps = f"  300     1 {app}/Contents/MacOS/unsloth-studio\n"
    listen = "p300\ncpython3.13\nn127.0.0.1:8888\n"

    def fake_run(command, timeout=10):
        if command and command[0] == "ps":
            return ps
        return listen if "LISTEN" in " ".join(command) else ""

    monkeypatch.setattr(recon, "_run", fake_run)

    # Found by the app's own display name, by the folder name, and by the path —
    # the folder is what both sides agree on when the labels differ.
    for entry in ("Unsloth", "Unsloth Studio", str(app)):
        assert {s.port for s in model_like_services(known_apps=[entry])} == {8888}, entry

    # A name that matches nothing still matches nothing: the register widens
    # recognition, it does not make every port inference.
    assert model_like_services(known_apps=["Something Else"]) == ()


def test_a_network_port_is_never_called_local_inference(machine):
    found = {service.port for service in model_like_services(known_apps=["other"])}
    assert found == set()


# --- outbound --------------------------------------------------------------


def test_outbound_connections_are_attributed_and_deduplicated(machine):
    connections = outbound_connections()
    keys = {(c.process, c.remote_host, c.remote_port) for c in connections}

    # Three records, two facts: the repeat is not a second connection.
    assert len(connections) == 2
    assert keys == {("python3.11", "127.0.0.1", 55001), ("other", "93.184.216.34", 443)}

    local_link = next(c for c in connections if c.remote_port == 55001)
    assert local_link.is_local_link is True
    assert local_link.app_name == "Some Studio"

    leaving = next(c for c in connections if c.remote_port == 443)
    assert leaving.is_local_link is False
    assert leaving.is_secure is True
    assert leaving.app_name == "Other"


# --- the behaviour ledger ---------------------------------------------------

#: Three apps: one serves a model and uses it, one serves and reaches outside
#: instead, one only reaches outside. That is the whole shape of the question.
LEDGER_PS = """\
  10     1 /Applications/Self.app/Contents/MacOS/self
  11    10 /Applications/Self.app/Contents/Helpers/server
  20     1 /Applications/Away.app/Contents/MacOS/away
  30     1 /Applications/Browser.app/Contents/MacOS/browser
"""

LEDGER_LISTEN = """\
p11
cpython3.11
n127.0.0.1:8123
p20
caway-server
n127.0.0.1:8124
"""

LEDGER_ESTABLISHED = """\
p10
cself
n127.0.0.1:55100->127.0.0.1:8123
p20
caway
n127.0.0.1:55101->93.184.216.34:443
p30
cbrowser
n127.0.0.1:55102->198.51.100.7:443
"""


@pytest.fixture
def ledger_machine(monkeypatch):
    def fake_run(command, timeout=10):
        if command and command[0] == "ps":
            return LEDGER_PS
        joined = " ".join(command)
        if "LISTEN" in joined:
            return LEDGER_LISTEN
        if "ESTABLISHED" in joined:
            return LEDGER_ESTABLISHED
        return ""

    monkeypatch.setattr(recon, "_run", fake_run)


def test_the_ledger_says_what_each_app_does_with_models(ledger_machine):
    rows = {
        row.name: row
        for row in recon.harness_ledger(known_apps=["Away", "Self"], answering={8123, 8124})
    }

    # Serves a model and is using it.
    assert rows["Self"].serves == (8123,)
    assert rows["Self"].using_own_server is True
    assert rows["Self"].reaches_out == ()

    # Serves a model, is not using it, and is reaching outside anyway.
    assert rows["Away"].serves == (8124,)
    assert rows["Away"].using_own_server is False
    assert rows["Away"].owns_idle_server is True

    # Reaches outside and serves nothing: reported, but never accused of idling.
    assert rows["Browser"].serves == ()
    assert rows["Browser"].owns_idle_server is False


def test_an_app_using_its_own_server_is_not_flagged(ledger_machine):
    """The flag has to be about the pair of observations, not about reaching out."""

    rows = {
        row.name: row
        for row in recon.harness_ledger(known_apps=["Away", "Self"], answering={8123, 8124})
    }
    assert rows["Self"].reaches_cloud is False
    assert rows["Self"].owns_idle_server is False


def test_the_ledger_leaves_a_stranger_out_of_the_sentences(ledger_machine):
    """A browser's ordinary traffic must not read as though it were a harness.

    An app that serves nothing and is not recognised is still reported by the
    other reconnaissance reads, and arrives as a register candidate instead.
    """

    lines = recon.ledger_lines(known_apps=["Away", "Self"], answering={8123, 8124})
    text = "\n".join(lines)

    assert "Away: serves models on 8124" in text
    assert "inbuilt server on 8124, reaching outside instead" in text
    assert "Browser" not in text
    # A server nobody is recognised for still earns a line: it is a model server.
    assert "Self: serves models on 8123" in text


def test_the_ledger_never_claims_a_server_is_neglected(ledger_machine):
    """ "Not using them" is a guess: the user may be Sea-Star itself."""

    text = "\n".join(recon.ledger_lines(known_apps=["Away", "Self"], answering={8123, 8124}))
    assert "not using them" not in text


# --- declared roles are barred from the ledger too --------------------------

def test_a_web_client_is_never_inference_and_never_in_the_ledger(tmp_path, monkeypatch):
    """A browser's loopback port is its own business, not a model server.

    Barred by the role it declares — ``http`` in its own Info.plist — so the rule
    holds for a browser nobody has written yet.
    """

    app = tmp_path / "Browser.app"
    contents = app / "Contents"
    contents.mkdir(parents=True)
    with (contents / "Info.plist").open("wb") as handle:
        plistlib.dump(
            {
                "CFBundleIdentifier": "test.browser",
                "CFBundleURLTypes": [{"CFBundleURLSchemes": ["http", "https"]}],
            },
            handle,
        )

    monkeypatch.setattr(
        recon,
        "listening_services",
        lambda: (
            ListeningService(
                pid=1,
                process="browser",
                port=9222,
                address="127.0.0.1",
                app_path=str(app),
                app_name="Browser",
            ),
        ),
    )

    # Recognised *and* listening on loopback, and still not inference.
    assert recon.model_like_services(known_apps=["Browser", str(app)]) == ()
    assert recon.harness_behaviour(known_apps=["Browser", str(app)]) == ()


def test_a_system_component_is_never_in_the_ledger(monkeypatch):
    monkeypatch.setattr(
        recon,
        "listening_services",
        lambda: (
            ListeningService(
                pid=1,
                process="ControlCenter",
                port=5000,
                address="127.0.0.1",
                app_path="/System/Library/CoreServices/ControlCenter.app",
                app_name="ControlCenter",
            ),
        ),
    )
    monkeypatch.setattr(recon, "process_table", dict)

    assert recon.harness_behaviour(known_apps=["ControlCenter"]) == ()


def test_a_port_that_never_answered_is_never_called_a_server(ledger_machine):
    """The correction that matters: a guessed port is reported as a guess.

    Found on a real machine. Unsloth's 8888 carries runtime vocabulary, owns the
    port and looks exactly like an inference server — and does not answer an
    OpenAI probe. The ledger said "serves models on 8888", which was a guess
    wearing the clothes of a fact, and this test exists so it cannot happen
    again.
    """

    # Nothing answered, so nothing may be stated as serving.
    rows = {
        row.name: row
        for row in recon.harness_ledger(known_apps=["Away", "Self"], answering=())
    }
    assert rows["Self"].serves == ()
    assert rows["Self"].listening == (8123,)
    assert rows["Self"].unconfirmed == (8123,)

    text = "\n".join(recon.ledger_lines(known_apps=["Away", "Self"], answering=()))
    assert "serves models" not in text
    assert "listening on 8123, not answering as a model server" in text


def test_the_flagged_case_requires_a_proved_server(ledger_machine):
    """An app cannot be accused of neglecting a server that never answered.

    Away reaches outside and owns a port. If that port is only a *guess*, saying
    "inbuilt server on 8124, reaching outside instead" would be an accusation
    built on an inference — the exact thing the ledger promises never to do.
    """

    guessed = {
        row.name: row
        for row in recon.harness_ledger(known_apps=["Away", "Self"], answering=())
    }
    assert guessed["Away"].owns_idle_server is False

    proved = {
        row.name: row
        for row in recon.harness_ledger(known_apps=["Away", "Self"], answering={8124})
    }
    assert proved["Away"].owns_idle_server is True
