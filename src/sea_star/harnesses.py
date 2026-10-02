"""Discover harnesses installed on this Mac, so the cockpit can float the latent ones.

A *harness* is anything Sea-Star can hand a model to. Two kinds matter here: the
local runtimes it already probes on a port (:func:`sea_star.config.probe_runtimes`),
and the apps that carry their own agent loop — an IDE is a harness too. A harness
that is installed but not answering is **latent**: it is not connected, but the
person may still want it on the graph rather than invisibly absent, so the cockpit
can toggle it on and off.

This module is a pure read of ``/Applications`` (plus ``~/Applications`` and any
mounted volume) — it never launches anything and never touches the network.
"""

from __future__ import annotations

import plistlib
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

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
}


@dataclass(frozen=True, slots=True)
class HarnessSpec:
    """One known harness app installed on this Mac but not answering on a port."""

    name: str
    bundle_id: str
    path: str


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
    volumes = Path(volumes_dir) if volumes_dir is not None else Path("/Volumes")
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
) -> tuple[HarnessSpec, ...]:
    """Known harness apps installed but not among the ``active`` (running) names.

    An app already answering on a port is not latent — the running harness owns
    that name and the graph draws it live — so it is dropped here to avoid a
    double. Everything else known is returned once, first install winning, in a
    stable order so the graph does not reshuffle between reads.
    """

    running = {name.casefold() for name in active}
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
            if known is None or known.casefold() in running:
                continue
            found.setdefault(
                bundle_id, HarnessSpec(name=known, bundle_id=bundle_id, path=str(app))
            )
    return tuple(found.values())
