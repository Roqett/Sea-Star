"""MCP client connections: proof that a host is attached over stdio.

Contract:
- Foundation §3 says *ask, don't guess*. A host that speaks MCP (TraeWork,
  Atomic Chat, Claude Desktop) never answers a port probe, so a port sweep can
  never see it — yet every ``sea-star serve`` process exists **because** one
  such host spawned it and keeps it alive exactly as long as the conversation
  lasts. The serve side therefore records who its parent is on start and
  removes the record on exit; ``doctor`` reads the live records and counts
  those hosts as active instead of latent.
- A record whose process is gone is pruned on read, so a crash can never leave
  a ghost claiming to be connected. Nothing here touches the network, and no
  record ever contains anything but this machine's own process names.
"""

from __future__ import annotations

import json
import os
import subprocess
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path

from .harnesses import KNOWN_HARNESS_APPS, _bundle_identity, app_bundle_in

#: Where live connection records live. Overridable for tests and unusual homes.
DEFAULT_STATE_DIR = Path.home() / ".seastar" / "clients"

#: How far to walk up the parent chain looking for an ``.app`` that launched us.
_MAX_ANCESTORS = 8


@dataclass(frozen=True, slots=True)
class ClientRecord:
    """One host currently holding a ``sea-star serve`` process open."""

    pid: int
    started_at: str
    name: str
    bundle_id: str | None
    app_path: str | None


def _state_dir(directory: Path | None = None) -> Path:
    if directory is not None:
        return directory
    override = os.environ.get("SEASTAR_CLIENTS_DIR")
    if override:
        return Path(override)
    return DEFAULT_STATE_DIR


def _process_info(pid: int) -> tuple[int, str] | None:
    """``(parent pid, executable path)`` for a live process, or ``None``."""

    try:
        result = subprocess.run(
            ["ps", "-p", str(pid), "-o", "ppid=", "-o", "command="],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    line = result.stdout.strip()
    if not line:
        return None
    parts = line.split(None, 1)
    if len(parts) != 2 or not parts[0].isdigit():
        return None
    return int(parts[0]), parts[1]


#: An absolute ``.app`` path, stopping at any shell delimiter. A parent's
#: command line may merely *mention* an app inside a script (``source
#: '/Applications/X.app'``), so only a clean path candidate counts. The pattern
#: itself lives with the harness table so both readers agree on what an app is.
def _app_in(command: str) -> Path | None:
    """The ``.app`` bundle this command runs inside, if any."""

    return app_bundle_in(command)


def _host_identity(pid: int) -> tuple[str, str | None, str | None]:
    """``(display name, bundle id, app path)`` of the app that owns this chain.

    Walks up the parent chain: a serve process is usually spawned by a helper
    (``uv``, a plugin sandbox), so the app that *decided* to connect sits a few
    rungs higher. Falls back to the nearest executable's basename.
    """

    current: int | None = pid
    fallback = ""
    for _ in range(_MAX_ANCESTORS):
        if current is None or current <= 1:
            break
        info = _process_info(current)
        if info is None:
            break
        parent, command = info
        if not fallback:
            fallback = Path(command).name or command
        app = _app_in(command)
        if app is not None:
            identity = _bundle_identity(app)
            if identity is not None:
                bundle_id, _installed_name = identity
                known = KNOWN_HARNESS_APPS.get(bundle_id, app.stem)
                return known, bundle_id, str(app)
            return app.stem, None, str(app)
        current = parent
    return fallback or "unknown", None, None


def record_client(pid: int | None = None, directory: Path | None = None) -> ClientRecord:
    """Announce that a host is connected. Best effort: never fails the serve."""

    own_pid = os.getpid() if pid is None else pid
    name, bundle_id, app_path = _host_identity(own_pid)
    record = ClientRecord(
        pid=own_pid,
        started_at=datetime.now(UTC).isoformat(timespec="seconds"),
        name=name,
        bundle_id=bundle_id,
        app_path=app_path,
    )
    target = _state_dir(directory)
    try:
        target.mkdir(parents=True, exist_ok=True)
        staging = target / f".{own_pid}.tmp"
        staging.write_text(json.dumps(asdict(record)), encoding="utf-8")
        staging.replace(target / f"{own_pid}.json")
    except OSError:
        pass
    return record


def clear_client(pid: int | None = None, directory: Path | None = None) -> None:
    """Drop the record for a serve process that is shutting down."""

    own_pid = os.getpid() if pid is None else pid
    try:
        (_state_dir(directory) / f"{own_pid}.json").unlink(missing_ok=True)
    except OSError:
        pass


def _pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def live_clients(directory: Path | None = None) -> tuple[ClientRecord, ...]:
    """Records whose process is still alive — the hosts actually attached now."""

    target = _state_dir(directory)
    try:
        files = sorted(target.glob("*.json"))
    except OSError:
        return ()
    live: list[ClientRecord] = []
    for path in files:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            record = ClientRecord(**payload)
        except (OSError, ValueError, TypeError):
            continue
        if not _pid_alive(record.pid):
            try:
                path.unlink(missing_ok=True)
            except OSError:
                pass
            continue
        live.append(record)
    return tuple(live)