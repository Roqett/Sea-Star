"""Discover harnesses installed on this Mac, and how far each one has climbed.

A *harness* is anything Sea-Star can hand a model to. Two kinds matter here: the
local runtimes it already probes on a port (:func:`sea_star.config.probe_runtimes`),
and the apps that carry their own agent loop — an IDE is a harness too, and so is
the harness the person is talking to right now.

A harness that is installed but not attached over MCP is **latent**: not connected,
but the person may still want it on the graph rather than invisibly absent. Latency
is not one state, so each spec carries the highest **rung** it has reached
(foundation §2):

- ``present``  — the bundle is installed; nothing is running.
- ``running``  — a process owns the bundle right now, but nothing answers on a port.
- ``listening``— a port probe answers in its name.
- ``caller-attributed`` — a live ``sea-star serve`` process records it as the host
  that spawned it (:mod:`sea_star.connections`), so Sea-Star knows *which* process
  is asking, not merely that something is up.

This module never launches anything and never touches the network. The process
table read is local and one-shot, taken only to tell ``running`` from ``present``.
"""

from __future__ import annotations

import plistlib
import re
import subprocess
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

#: Ladder rungs this module can observe (foundation §2 capability ladder).
RUNG_PRESENT = "present"
RUNG_RUNNING = "running"
RUNG_LISTENING = "listening"
RUNG_CALLER_ATTRIBUTED = "caller-attributed"

#: An absolute ``.app`` path, stopping at any shell delimiter. A process command
#: may merely *mention* an app inside a script (``source '/Applications/X.app'``),
#: so only a clean path candidate counts.
_APP_PATH = re.compile(r"(/[^;|&=\"'\n\r\t]*?\.app)(?![A-Za-z0-9.])")


def app_bundle_in(command: str) -> Path | None:
    """The ``.app`` bundle a command line runs inside, if any."""

    for match in _APP_PATH.finditer(command):
        app = Path(match.group(1))
        if app.name.endswith(".app"):
            return app
    return None


def running_app_paths() -> frozenset[str]:
    """Every ``.app`` bundle with a live process right now.

    One ``ps`` read, no interpretation: a bundle appearing here is running, and
    one that does not appear is not. Failures return an empty set — a machine
    where the process table cannot be read degrades to ``present`` rather than
    claiming a harness is up.
    """

    try:
        result = subprocess.run(
            ["ps", "-ax", "-o", "command="],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return frozenset()
    found: set[str] = set()
    for line in result.stdout.splitlines():
        app = app_bundle_in(line)
        if app is not None:
            found.add(str(app))
    return frozenset(found)

#: Bundle id -> display name, for the harness apps worth naming on the graph.
#: Only tools that carry their own model-driven loop belong here: an IDE that
#: hosts an agent, or a runtime's own app. The vault host (Obsidian) is not a
#: harness — it is the pool Sea-Star swims in.
KNOWN_HARNESS_APPS: dict[str, str] = {
    "com.dinoki.osaurus": "Osaurus",
    "app.omlx": "oMLX",
    "com.apple.dt.Xcode": "Xcode",
    "ai.opencode.desktop": "OpenCode",
    "ai.opencode.desktop.beta": "OpenCode (Beta)",
    "com.trae.app": "TraeCode",
    "com.trae.solo.app": "TraeWork",
    "com.electron.goose": "Goose",
    "ai.unsloth.studio": "Unsloth Studio",
    "com.deepseek.dsh": "DeepSeek Harness",
}


@dataclass(frozen=True, slots=True)
class HarnessSpec:
    """One known harness app installed on this Mac but not attached over MCP.

    ``rung`` is the highest ladder rung observed for it, so a caller can say
    "running, not answering" instead of flattening every unattached harness to
    the same grey absence.
    """

    name: str
    bundle_id: str
    path: str
    rung: str = RUNG_PRESENT


def _bundle_identity(app: Path) -> tuple[str, str] | None:
    """``(bundle_id, display_name)`` for an ``.app``, or ``None`` if unreadable."""

    try:
        with (app / "Contents" / "Info.plist").open("rb") as handle:
            info = plistlib.load(handle)
    except (OSError, ValueError):
        return None
    if not isinstance(info, dict):
        return None
    bundle_id = info.get("CFBundleIdentifier")
    if not isinstance(bundle_id, str) or not bundle_id:
        return None
    name = info.get("CFBundleDisplayName") or info.get("CFBundleName") or app.stem
    return bundle_id, str(name)


#: URL schemes that only a general-purpose web client claims. A browser *must*
#: declare these in its own Info.plist to be offered as a handler, so this is the
#: operating system's own browser list — read, not guessed, and it will still be
#: right for a browser nobody has written yet.
WEB_CLIENT_SCHEMES = frozenset({"http", "https"})


def declared_url_schemes(app: Path) -> frozenset[str]:
    """The URL schemes an app claims in its own bundle, lowercased."""

    try:
        with (app / "Contents" / "Info.plist").open("rb") as handle:
            info = plistlib.load(handle)
    except (OSError, ValueError):
        return frozenset()
    if not isinstance(info, dict):
        return frozenset()
    schemes: set[str] = set()
    for entry in info.get("CFBundleURLTypes") or []:
        if not isinstance(entry, dict):
            continue
        for scheme in entry.get("CFBundleURLSchemes") or []:
            schemes.add(str(scheme).lower())
    return frozenset(schemes)


def is_web_client(app: Path, path_text: str | None = None) -> bool:
    """Whether an app declares itself a general-purpose web client.

    Deliberately a *category*, never a name: browsers are excluded from harness
    classification because being a browser is a declared role, and because their
    traffic is discretionary — a person with a browser open has not told us
    anything about how they use models, and treating it as though they had buries
    the real harnesses in noise.
    """

    return bool(declared_url_schemes(app) & WEB_CLIENT_SCHEMES)


def is_system_component(path_text: str | None) -> bool:
    """Whether a bundle belongs to the operating system rather than to a person.

    ``/System`` covers ControlCenter and its AirPlay ports, and anything else
    Apple ships as a service. It is the operating system doing its job, not a
    harness, and no name list is needed to say so.
    """

    return bool(path_text) and str(path_text).startswith("/System/")


def _application_dirs(
    *,
    home: Path | None = None,
    system_dir: Path | None = None,
    volumes_dir: Path | None = None,
) -> tuple[Path, ...]:
    """Every place macOS keeps an app: the two Applications folders and volumes."""

    base = (home or Path.home()).expanduser()
    system = Path("/Applications") if system_dir is None else Path(system_dir)
    dirs = [system, base / "Applications"]
    # A mounted volume is read **only when a caller names it**. Sea-Star must not
    # go looking on removable drives of its own accord: the founder's no-go rule
    # puts his external drive and any mirror of it off-limits, and an
    # unconditional `/Volumes` sweep is exactly the kind of quiet visit that rule
    # exists to prevent. Passing ``volumes_dir`` is the deliberate ask.
    if volumes_dir is not None:
        volumes = Path(volumes_dir)
        if volumes.is_dir():
            try:
                mounted = sorted(volume for volume in volumes.iterdir() if volume.is_dir())
            except OSError:
                mounted = []
            dirs.extend(volume / "Applications" for volume in mounted)
    return tuple(dirs)


def detect_latent_harnesses(
    *,
    active: Iterable[str] = (),
    home: Path | None = None,
    system_dir: Path | None = None,
    volumes_dir: Path | None = None,
    running: Iterable[str] | None = None,
) -> tuple[HarnessSpec, ...]:
    """Known harness apps installed but not attached, each with its rung.

    An app already answering on a port is not latent — the running harness owns
    that name and the graph draws it live — so it is dropped here to avoid a
    double. Everything else known is returned once, first install winning, in a
    stable order so the graph does not reshuffle between reads.

    ``running`` is the set of bundle paths currently owned by a process; ``None``
    reads the real process table. Injecting it keeps the caller honest: a harness
    is called running on evidence, never on assumption.
    """

    running_names = {name.casefold() for name in active}
    live_paths = running_app_paths() if running is None else frozenset(running)
    found: dict[str, HarnessSpec] = {}
    for directory in _application_dirs(
        home=home, system_dir=system_dir, volumes_dir=volumes_dir
    ):
        if not directory.is_dir():
            continue
        try:
            apps = sorted(directory.glob("*.app"))
        except OSError:
            continue
        for app in apps:
            identity = _bundle_identity(app)
            if identity is None:
                continue
            bundle_id, _installed_name = identity
            known = KNOWN_HARNESS_APPS.get(bundle_id)
            if known is None or known.casefold() in running_names:
                continue
            rung = RUNG_RUNNING if str(app) in live_paths else RUNG_PRESENT
            found.setdefault(
                bundle_id,
                HarnessSpec(name=known, bundle_id=bundle_id, path=str(app), rung=rung),
            )
    return tuple(found.values())
