"""Latent-harness discovery: known apps installed but not answering on a port."""

from __future__ import annotations

import plistlib
from pathlib import Path

from sea_star.harnesses import HarnessSpec, detect_latent_harnesses


def _make_app(directory: Path, filename: str, bundle_id: str, display_name: str) -> Path:
    app = directory / filename
    contents = app / "Contents"
    contents.mkdir(parents=True)
    with (contents / "Info.plist").open("wb") as handle:
        plistlib.dump(
            {"CFBundleIdentifier": bundle_id, "CFBundleDisplayName": display_name}, handle
        )
    return app


def _home_with_apps(tmp_path: Path, *apps: tuple[str, str]) -> Path:
    apps_dir = tmp_path / "Applications"
    apps_dir.mkdir(parents=True)
    for filename, bundle_id in apps:
        _make_app(apps_dir, filename, bundle_id, filename.removesuffix(".app"))
    return tmp_path


def _detect(tmp_path: Path, **kwargs):
    # Point every root at the temp tree so the real /Applications and /Volumes
    # are never read.
    kwargs.setdefault("system_dir", tmp_path / "no-system")
    kwargs.setdefault("volumes_dir", tmp_path / "no-volumes")
    return detect_latent_harnesses(**kwargs)


def test_detects_known_installed_harness(tmp_path):
    home = _home_with_apps(tmp_path, ("Xcode.app", "com.apple.dt.Xcode"))
    found = _detect(tmp_path, home=home)
    assert found == (
        HarnessSpec(
            name="Xcode",
            bundle_id="com.apple.dt.Xcode",
            path=str(home / "Applications" / "Xcode.app"),
        ),
    )


def test_ignores_unknown_bundle_ids(tmp_path):
    home = _home_with_apps(tmp_path, ("SomeApp.app", "com.example.something"))
    assert _detect(tmp_path, home=home) == ()


def test_drops_active_harness(tmp_path):
    home = _home_with_apps(tmp_path, ("Goose.app", "com.electron.goose"))
    assert _detect(tmp_path, home=home, active=("goose",)) == ()


def test_active_match_is_casefolded(tmp_path):
    home = _home_with_apps(tmp_path, ("Xcode.app", "com.apple.dt.Xcode"))
    assert _detect(tmp_path, home=home, active=("XCODE",)) == ()


def test_skips_app_without_bundle_id(tmp_path):
    apps_dir = tmp_path / "Applications"
    apps_dir.mkdir(parents=True)
    contents = apps_dir / "Nameless.app" / "Contents"
    contents.mkdir(parents=True)
    with (contents / "Info.plist").open("wb") as handle:
        plistlib.dump({"CFBundleName": "Nameless"}, handle)
    assert _detect(tmp_path, home=tmp_path) == ()


def test_skips_unreadable_app(tmp_path):
    apps_dir = tmp_path / "Applications"
    apps_dir.mkdir(parents=True)
    (apps_dir / "Broken.app").mkdir()
    assert _detect(tmp_path, home=tmp_path) == ()


def test_dedupes_same_bundle_across_dirs(tmp_path):
    home = _home_with_apps(tmp_path, ("Xcode.app", "com.apple.dt.Xcode"))
    _make_app(home / "Applications", "Xcode Copy.app", "com.apple.dt.Xcode", "Xcode Copy")
    found = _detect(tmp_path, home=home)
    assert len(found) == 1
    assert found[0].bundle_id == "com.apple.dt.Xcode"


def test_scans_mounted_volumes(tmp_path):
    volumes = tmp_path / "Volumes"
    volume_apps = volumes / "ExtDrive" / "Applications"
    volume_apps.mkdir(parents=True)
    _make_app(volume_apps, "OpenCode.app", "ai.opencode.desktop", "OpenCode")
    home = tmp_path / "home"
    home.mkdir()
    found = _detect(tmp_path, home=home, volumes_dir=volumes)
    assert found == (
        HarnessSpec(
            name="OpenCode",
            bundle_id="ai.opencode.desktop",
            path=str(volume_apps / "OpenCode.app"),
        ),
    )
