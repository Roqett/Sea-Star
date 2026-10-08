"""Harness discovery: known apps installed, and the rung each one reached."""

from __future__ import annotations

import plistlib
from pathlib import Path

from sea_star.harnesses import (
    KNOWN_HARNESS_COMMANDS,
    HarnessSpec,
    app_bundle_in,
    detect_latent_harnesses,
    serving_harness_processes,
)


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
    # are never read, and pin both process reads so a test never depends on what
    # happens to be open on the machine running it.
    kwargs.setdefault("system_dir", tmp_path / "no-system")
    kwargs.setdefault("running", ())
    kwargs.setdefault("commands", ())
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


def test_scans_mounted_volumes_only_when_asked(tmp_path):
    """A volume is read because a caller named it, never because it is mounted."""

    volumes = tmp_path / "Volumes"
    volume_apps = volumes / "ExtDrive" / "Applications"
    volume_apps.mkdir(parents=True)
    _make_app(volume_apps, "OpenCode.app", "ai.opencode.desktop", "OpenCode")
    home = tmp_path / "home"
    home.mkdir()

    # The default read does not go near a mounted volume: the founder's no-go
    # rule covers his external drive, and a silent sweep would breach it.
    assert _detect(tmp_path, home=home) == ()

    found = _detect(tmp_path, home=home, volumes_dir=volumes)
    assert found == (
        HarnessSpec(
            name="OpenCode",
            bundle_id="ai.opencode.desktop",
            path=str(volume_apps / "OpenCode.app"),
        ),
    )


def test_installed_but_closed_is_present(tmp_path):
    home = _home_with_apps(tmp_path, ("Xcode.app", "com.apple.dt.Xcode"))
    found = _detect(tmp_path, home=home, running=("/Applications/Safari.app",))
    assert found[0].rung == "present"


def test_running_bundle_climbs_to_running(tmp_path):
    """A process owning the bundle is evidence, so the rung says so."""

    home = _home_with_apps(tmp_path, ("DeepSeek Harness.app", "com.deepseek.dsh"))
    found = _detect(tmp_path, home=home, running=(str(home / "Applications" / "DeepSeek Harness.app"),))
    assert found == (
        HarnessSpec(
            name="DeepSeek Harness",
            bundle_id="com.deepseek.dsh",
            path=str(home / "Applications" / "DeepSeek Harness.app"),
            rung="running",
        ),
    )


def test_app_bundle_in_reads_a_path_out_of_a_command_line():
    assert app_bundle_in("/Applications/DeepSeek Harness.app/Contents/MacOS/x --flag") == Path(
        "/Applications/DeepSeek Harness.app"
    )


def test_app_bundle_in_stops_at_the_shell_delimiter():
    """A quoted or trailing token is not swallowed into the app path."""

    assert app_bundle_in("open '/Applications/Safari.app'; echo done") == Path(
        "/Applications/Safari.app"
    )
    assert app_bundle_in("/usr/bin/python3 -m sea_star.cli serve") is None


# The bug this pins: OpenCode was running as a bare CLI binary, and Sea-Star
# could only see `.app` bundles — so a harness that was demonstrably open read as
# latent, or as nothing at all.
def test_running_cli_harness_is_reported_running(tmp_path):
    found = _detect(tmp_path, home=tmp_path, commands=("OpenCode",))
    assert found == (
        HarnessSpec(name="OpenCode", bundle_id="cli:opencode", path="OpenCode", rung="running"),
    )


def test_cli_harness_stands_for_its_installed_desktop_sibling(tmp_path):
    """One product, one row: a running command must not leave the installed app
    beside it, or OpenCode appears twice and reads as two different things."""

    home = _home_with_apps(tmp_path, ("OpenCode.app", "ai.opencode.desktop"))
    found = _detect(tmp_path, home=home, commands=("OpenCode",))
    assert [spec.bundle_id for spec in found] == ["cli:opencode"]


def test_attached_cli_harness_is_not_listed_twice(tmp_path):
    """An attached harness is already drawn live by the graph."""

    assert _detect(tmp_path, home=tmp_path, active=("OpenCode",), commands=("OpenCode",)) == ()


def test_stopped_cli_harness_is_not_invented(tmp_path):
    """A CLI agent has no install to scan, so nothing is reported when it is not
    running — the list may not claim a process that is not there."""

    assert _detect(tmp_path, home=tmp_path, commands=()) == ()


def test_a_cli_serving_a_model_is_found_without_being_on_any_list(tmp_path):
    """The whole point of asking what a process *does*.

    A CLI agent invented after ``KNOWN_HARNESS_COMMANDS`` was written has no
    bundle, no Info.plist and no name anyone here has heard of. If recognition
    depended on the name it would be invisible forever, which for a headless agent
    is not a gap in coverage but the entire mechanism failing. Serving a model on
    loopback is evidence that needs no name, so it is reported.
    """

    found = _detect(
        tmp_path,
        home=tmp_path,
        serving=serving_harness_processes(
            serving_ports=(7788,),
            port_owners={7788: "nightfall-agent"},
        ),
    )
    assert [spec.bundle_id for spec in found] == ["cli:nightfall-agent"]
    assert found[0].rung == "running"


def test_a_serving_port_with_no_owner_is_not_claimed(tmp_path):
    """An unowned port is not evidence of a process. Guessing here is the exact
    failure the foundation forbids — inventing a harness that may not exist."""

    assert serving_harness_processes(serving_ports=(7788,), port_owners={}) == frozenset()
    assert serving_harness_processes(serving_ports=(7788,), port_owners={7788: "  "}) == frozenset()


def test_no_serving_ports_means_no_harnesses_from_behaviour(tmp_path):
    """Absent proof that anything served a model, this family contributes nothing
    rather than falling back to a guess."""

    assert serving_harness_processes() == frozenset()


def test_a_serving_process_is_named_not_duplicated_alongside_its_app(tmp_path):
    """One product, one row — and the *running* one wins.

    A process serving on loopback is the same product as its installed app, so
    reporting both would read as two different tools. Which of the two survives is
    the existing rule rather than a new one: a running command stands in for its
    installed desktop sibling, because it is the more current fact. This is the
    same substitution OpenCode already gets, reached here without its name.
    """

    home = _home_with_apps(tmp_path, ("Nightfall.app", "ai.nightfall.app"))
    found = _detect(
        tmp_path,
        home=home,
        serving=serving_harness_processes(
            serving_ports=(7788,), port_owners={7788: "Nightfall"}
        ),
    )
    assert [spec.bundle_id for spec in found] == ["cli:nightfall"]
    assert found[0].rung == "running"


def test_the_name_list_is_only_a_hint_not_a_gate(tmp_path):
    """The six known command names stay useful, but nothing about recognition may
    depend on membership of that dict — which is why an unknown name above is
    found at all."""

    assert "nightfall-agent" not in KNOWN_HARNESS_COMMANDS
    assert serving_harness_processes(
        serving_ports=(7788,), port_owners={7788: "nightfall-agent"}
    ) == frozenset({"nightfall-agent"})
