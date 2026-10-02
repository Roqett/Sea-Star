"""MCP client records: who is attached over stdio, and how ghosts get pruned."""

from __future__ import annotations

import json
import os
from pathlib import Path

from sea_star.connections import (
    ClientRecord,
    clear_client,
    live_clients,
    record_client,
)


def test_record_then_live_roundtrip(tmp_path, monkeypatch):
    monkeypatch.delenv("SEASTAR_CLIENTS_DIR", raising=False)
    monkeypatch.setattr(
        "sea_star.connections._host_identity",
        lambda pid: ("TraeWork", "com.trae.solo.app", "/Applications/TRAE SOLO.app"),
    )

    record = record_client(pid=os.getpid(), directory=tmp_path)
    live = live_clients(directory=tmp_path)

    assert record.name == "TraeWork"
    assert live == (record,)
    assert json.loads((tmp_path / f"{os.getpid()}.json").read_text())["bundle_id"] == (
        "com.trae.solo.app"
    )


def test_clear_client_removes_the_record(tmp_path, monkeypatch):
    monkeypatch.setattr(
        "sea_star.connections._host_identity",
        lambda pid: ("Atomic Chat", None, "/Applications/Atomic Chat.app"),
    )
    record_client(pid=os.getpid(), directory=tmp_path)

    clear_client(pid=os.getpid(), directory=tmp_path)

    assert live_clients(directory=tmp_path) == ()


def test_a_dead_process_is_pruned_not_reported(tmp_path, monkeypatch):
    """A crash must never leave a ghost claiming to be connected."""

    ghost_pid = 999_999_991
    while True:
        try:
            os.kill(ghost_pid, 0)
        except PermissionError:
            ghost_pid += 1
            continue
        except ProcessLookupError:
            break
        ghost_pid += 1
    (tmp_path / f"{ghost_pid}.json").write_text(
        json.dumps(
            {
                "pid": ghost_pid,
                "started_at": "2026-09-30T00:00:00+00:00",
                "name": "Gone",
                "bundle_id": None,
                "app_path": None,
            }
        ),
        encoding="utf-8",
    )

    assert live_clients(directory=tmp_path) == ()
    assert not (tmp_path / f"{ghost_pid}.json").exists()


def test_unreadable_records_are_skipped_not_fatal(tmp_path):
    (tmp_path / "123.json").write_text("{not json", encoding="utf-8")

    assert live_clients(directory=tmp_path) == ()


def test_missing_directory_reads_as_no_clients(tmp_path):
    assert live_clients(directory=tmp_path / "nowhere") == ()


def test_env_override_moves_the_state_dir(tmp_path, monkeypatch):
    monkeypatch.setenv("SEASTAR_CLIENTS_DIR", str(tmp_path / "elsewhere"))
    monkeypatch.setattr(
        "sea_star.connections._host_identity",
        lambda pid: ("TraeWork", "com.trae.solo.app", None),
    )

    record_client(pid=os.getpid())

    assert (tmp_path / "elsewhere" / f"{os.getpid()}.json").exists()
    clear_client(pid=os.getpid())


def test_host_identity_walks_up_to_the_owning_app(tmp_path, monkeypatch):
    from sea_star import connections

    steps = {
        os.getpid(): (1234, "/opt/homebrew/bin/uv"),
        1234: (5420, "/Applications/TRAE SOLO.app/Contents/Frameworks/TRAE SOLO Helper (Plugin)"),
        5420: (1, "/sbin/launchd"),
    }
    monkeypatch.setattr(connections, "_process_info", lambda pid: steps.get(pid))

    name, bundle_id, app_path = connections._host_identity(os.getpid())

    assert name == "TraeWork"
    assert bundle_id == "com.trae.solo.app"
    assert app_path == "/Applications/TRAE SOLO.app"


def test_host_identity_falls_back_to_the_nearest_binary(monkeypatch):
    from sea_star import connections

    monkeypatch.setattr(
        connections,
        "_process_info",
        lambda pid: (1, "/usr/local/bin/someagent") if pid == os.getpid() else None,
    )

    name, bundle_id, app_path = connections._host_identity(os.getpid())

    assert name == "someagent"
    assert bundle_id is None
    assert app_path is None


def test_app_in_finds_the_bundle_behind_shell_text():
    """A parent command may only *mention* an app inside a sourced script."""

    from sea_star.connections import _app_in

    command = "/bin/zsh -c . '/Users/me/.trae/profile.sh' 2>/dev/null; source '/Applications/TRAE SOLO.app'"

    assert _app_in(command) == Path("/Applications/TRAE SOLO.app")


def test_app_in_accepts_a_direct_executable_inside_a_bundle():
    from sea_star.connections import _app_in

    command = "/Applications/TRAE SOLO.app/Contents/Frameworks/TRAE SOLO Helper (Plugin) --flag"

    assert _app_in(command) == Path("/Applications/TRAE SOLO.app")


def test_app_in_ignores_lookalike_extensions_and_junk():
    from sea_star.connections import _app_in

    assert _app_in("/usr/bin/python do.py app.application") is None
    assert _app_in("/bin/zsh -c 'echo hi'") is None
    assert _app_in("/Applications/Foo.app.bak/Contents/x") is None


def test_record_never_raises_when_the_state_dir_is_unwritable(tmp_path, monkeypatch):
    monkeypatch.setattr(
        "sea_star.connections._host_identity",
        lambda pid: ("TraeWork", None, None),
    )
    blocker = tmp_path / "blocker"
    blocker.write_text("a file, not a directory", encoding="utf-8")

    record = record_client(pid=os.getpid(), directory=blocker)

    assert isinstance(record, ClientRecord)