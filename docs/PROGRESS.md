# Progress

Live build state and session handoff. Read this before starting work; append a handoff
note at the end of every session.

## Current state

- **Version:** 0.1.0 (unreleased). Repo is **private** until built and tested.
- **Health:** `uv run ruff check .` clean; `uv run pytest` — 51 passing. App:
  `xcodebuild … test` — 28 Swift Testing cases passing (8 suites).
- **Bridge:** `sea-star doctor --json` now emits the full §6 contract —
  `schema_version`, nested `vault {path, source, note_count, candidates}`, `server.state`,
  and `runtimes[]` (one object per live harness). Always one JSON object, even on failure.
  `include` / `exclude` tool curation is wired through `config.py` → `mcp_client.py`.
- **Cockpit (new):** the macOS menu-bar app exists under `macapp/` (XcodeGen + SwiftUI).
  It builds, launches, and its 12 Swift Testing cases pass. Popover shows vault/harness/model
  and its vault, model and harness rows are pick-lists (T3.2/T3.3 + multi-harness), switching
  via `SEASTAR_VAULT` / `SEASTAR_MODEL` / `SEASTAR_BASE_URL`+`SEASTAR_RUNTIME`. It holds **all four founder icons in one roster** (`IconRoster`) and
  rerolls to a different face on server start/stop — the "open and shut" Easter egg (T4.7) —
  shown on both the menu-bar glyph and the popover header. Faces now wear the founder's
  **real art** (T4.3) as a **single cut each** (`Face*Header`), rendered as a **template** on
  every surface — the menu bar takes the system's tint (white-on-dark / black-on-light), so the
  detailed starfish stays legible in both appearances instead of the old solid star. The header
  face carries a caustic shimmer (T4.5) via `Shaders/Caustics.metal`.
- **Cockpit: standard app menu (new).** The shell is now AppKit-hosted (`@main enum
  SeaStarMain` → `App/AppDelegate.swift`) because `MenuBarExtra` has no right-click hook. The
  status item's **right-click** shows the standard app menu — Check for Updates…, Settings…
  (⌘,), Help & Comments, Patchdog, a version line, Quit — and **Settings…** opens a proper
  `Views/SettingsView.swift` window (engine + searchable vault list + harness/model + updates
  + links). Updates check the GitHub Releases API (`Services/UpdateChecker.swift`). The
  popover's detail body **scrolls**; the vault row gained **Open folder…**; the model row
  follows the **selected harness**.
- **Cockpit: strips, logs and the starfield (new).** The Start/Refresh glass pills are gone —
  plain mono words, **Start left / Refresh right**, a **blue-white nudibranch strip** above and
  below the pair (`Views/NudiStrip.swift`; the founder's three 3px ribbons are now imagesets).
  A collapsible **Logs** panel (strips top and bottom, SF Mono, blue ink, selectable) reads from
  a new `Services/LogStore.swift` that pipes engine `stdout`/`stderr` to
  `~/Library/Logs/Sea-Star/sea-star.log` and **prunes on every write** against a retention
  window set in Settings → **Logs** (Forever / 7 / 14 / 30, default 14; **Clear now** + **Reveal
  in Finder**). A segmented **Graph | List** toggle (List default) opens the **entity graph**
  (`Views/EntityGraphView.swift`): vault/harnesses/models as glowing nodes, the vault↔harness
  connection drawn as a rotated nudibranch strip, tap-to-select via the same controller calls.
- **Cockpit: light/dark chrome, dark starfield (new).** `Support/Palette.swift` splits into an
  **adaptive chrome** layer (`canvas`/`ink`/`inkMuted`/`logInk`/`logSurface`, via an `NSColor`
  dynamic provider keyed on `bestMatch(.darkAqua/.aqua)`) and a **fixed-dark `pool`** used by the
  entity graph — so both panels follow the system appearance while the starfield stays black.
  Sampled both appearances offscreen to confirm the swap.
- **Naming:** repo is **`Roqett/Sea-Star`** (personal — keeps the history on the founder's
  profile). "Up Periscope" is the **product identity** (licence + bundle id), not a GitHub
  org. Codeberg remote is `Touretro/theSeaStar`.
- **Runtime on this machine:** Osaurus running on `http://127.0.0.1:1337/v1`, model
  `foundation` (Apple on-device, zero downloads, macOS 26+). `sea-star doctor` prints
  **Ready**.
- **Vault:** autodetected from Obsidian; a throwaway `demo-vault/` is used for testing.

## What exists

| Area | File | State |
| --- | --- | --- |
| CLI | `src/sea_star/cli.py` | Done — `version`, `init`, `doctor` (incl. `--json`), `ask`, `serve`. |
| Config + autodetect | `src/sea_star/config.py` | Done — runtime probe, `obsidian.json` vault detect, `include`/`exclude` (`allows()`). |
| Inference | `src/sea_star/inference.py` | Done — OpenAI-compatible over raw `httpx`. |
| Vault | `src/sea_star/vault.py` | Done — scan, search, read, write, append, citations. |
| Tools | `src/sea_star/tools.py` | Done — registry + 4 built-in vault tools. |
| Agent loop | `src/sea_star/agent.py` | Done — bounded loop, citations, fail-loud. |
| MCP server | `src/sea_star/mcp_server.py` | Done — exposes `ask_seastar`, `vault_*`. |
| MCP client | `src/sea_star/mcp_client.py` | Done — bridges external servers, namespaced, curated by `include`/`exclude`. |
| Docs | `docs/` | **Added this session** — tiered: start-here → connect → reference → troubleshooting. |
| Cockpit (mac app) | `macapp/` | **New** — XcodeGen project; **AppKit-hosted** SwiftUI (`SeaStarMain` → `AppDelegate`, `NSStatusItem` + `NSPopover`). `App/ Views/ Models/ Services/ Support/ Shaders/`; builds, launches, 28 Swift tests pass. Right-click app menu + Settings window + GitHub-Releases update check. Vault + model + harness pick-lists wired to `SEASTAR_VAULT`/`SEASTAR_MODEL`/`SEASTAR_BASE_URL`. Four-face icon roster rerolls on start/stop (T4.7); real T4.3/T4.4 cuts; header caustic shimmer (T4.5). |

## File ownership

No parallel agents active. Single-writer.

## Handoff — previous session

**Completed**

- Built the `docs/` folder: a docs index, a zero-jargon `start-here.md`, the
  `connect.md` guide (the previously missing "how do I wire Sea-Star into Osaurus / Claude
  Desktop / Cursor / TRAE" instructions, plus what to say to the agents), a technical
  `reference.md`, and `troubleshooting.md`.
- Wired the repository `README.md` to the docs index with a Documentation section.
- Confirmed live state: repo `Roqett/Sea-Star` on `main`, v0.1.0, Osaurus on 1337,
  `doctor` Ready.

**Half-finished / open**

- Nothing in the code. Docs are written but not yet reviewed by the founder.
- Roadmap items still open: semantic (embedding) recall, `.mcpb` one-click Desktop
  Extension, a local-model/MCP conformance table.

**Single next step**

- Founder reviews the new `docs/` pages. If approved, this is a natural point to flip the
  repository from private to public.

## Handoff — 2026-09-25

**Completed**

- Shipped the **app bridge contract**: `sea-star doctor --json` always returns one JSON
  object (vault, notes, runtime, base_url, model, models, bridged servers), even on failure.
- Added **`include` / `exclude`** tool curation to `[[mcp.servers]]`, applied at connect
  time in `mcp_client.list_external_tools` so the agent sees a short tool menu.
- Rewrote `README.md` as **two equal tracks** (terminal-first now, GUI-first coming) with a
  parity table; removed the marketing pull-quote and the `## The name` section.
- Took the mac-app spec to **Revision 2**: dual-track model (D9), identity/naming (D10),
  corrected Xcode toolchain + native `xcrun mcpbridge` path (§9.1), Omarchy port (§3).
- Added `docs/README_DRY.md` — a spin-free reference doc for cross-checking the Omarchy
  port with other models.

**Half-finished / open**

- **Naming resolved — stays personal.** The repo stays at `Roqett/Sea-Star` so the history
  shows on the founder's profile. Notarisation and the bundle id depend on the **Apple
  Developer account, not GitHub**, so no org is needed. All links were repointed from
  `UpPeriscope/Sea-Star` back to `Roqett/Sea-Star`.
- **Spec set is now tracked.** `.trae/specs/mac-app/` (`spec.md`, `tasks.md`,
  `checklist.md`) is committed; `.trae/*` is gitignored except `specs/`.
- Bridge tests for `--json` and `allows()` (spec T1.5/T1.6/T1.8) not yet written.

**Single next step**

- Founder reviews the rewritten `README.md` + the spec Revision 2, then the repo can go
  public (naming settled: stays at `Roqett/Sea-Star`).

## Handoff — 2026-09-25 (cockpit scaffold)

**Completed**

- **Bridge finished to the §6 contract.** `doctor --json` now emits `schema_version`, a
  nested `vault {path, source, note_count, candidates}` object, and `server.state`; still
  one JSON object always, human output still default. New vault helpers in `config.py`:
  `detect_vault_candidates()` (open-first, then most-recent) and `resolve_vault()` →
  `(path, source)` with `source` ∈ `env`/`toml`/`obsidian`, failing loud.
- **Tests added:** `tests/test_cli.py` (bridge shape, fail-loud one object, human default)
  and additions to `tests/test_config.py` (vault candidates/resolution, `allows()`).
  Engine: `uv run ruff check .` clean, `uv run pytest` → **40 passing**.
- **macOS menu-bar app scaffolded** under `macapp/`: XcodeGen `project.yml`, SwiftUI
  `MenuBarExtra` with `.menuBarExtraStyle(.window)`, files split by responsibility.
  `EngineClient` runs `sea-star doctor --json` and decodes it; `ServerController` owns
  refresh + start/stop of `sea-star serve`; popover renders vault/harness/model with the
  Carpet Sea Star palette and glass controls. Bundle id `UpPeriscope.Sea-Star`, target
  macOS 26.0. Builds, launches, **4 Swift Testing cases pass**.
- **Verified:** `xcodegen generate` → `xcodebuild ... build` → `** BUILD SUCCEEDED **`;
  `xcodebuild ... test` → `** TEST SUCCEEDED **`; app launches without crashing.

**Half-finished / open**

- Menu-bar icon is a **placeholder SF Symbol** (`Strings.MenuBar.systemImage`); the
  founder is producing the real monochrome template image (spec T4.3/T4.4).
- Popover shows the detected vault/harness/model, but the **vault pick-list (T3.2)** and
  **model pick-list (T3.3)** are not built yet — the bridge already carries
  `vault.candidates`, so those can read straight from the report.
- Start/stop spawns `sea-star serve` and terminates it; it does not yet watch the child's
  exit, so state can go stale if the process dies on its own.
- Graph embedding (T4.2), re-index (T4.1), and both operator instruction docs (T6.x) are
  untouched.

**Single next step**

- Build the vault pick-list (T3.2): a menu in the popover listing `report.vault.candidates`,
  with the current vault checked, switching by re-running the engine with `SEASTAR_VAULT`.

## Handoff — 2026-09-25 (cockpit pick-lists)

**Completed**

- **Vault pick-list (T3.2) and model pick-list (T3.3).** The popover's vault and model rows
  are now menus: the vault menu lists `report.vault.candidates` (the current vault is always
  included, even when it came from env/TOML), the model menu lists `report.models`. The
  current choice shows in-row, is checked in the menu, and the control disables itself when
  there is nothing to switch to. New `PickerRow` (plus a shared `AccentBar`) in
  `CockpitPopoverView`.
- **Switching needs no engine change.** `EngineCommand.Invocation` now carries an
  `environment` map (`EngineCommand.vaultOverrideKey`/`modelOverrideKey` = `SEASTAR_VAULT` /
  `SEASTAR_MODEL`), merged over the inherited environment in `ProcessRunner` and in
  `ServerController.startServer`. Changing a choice re-runs `doctor --json` with the pin, and
  **restarts a running server** so the new vault/model takes effect.
- **Tests:** new Swift Testing cases for the env threading and the empty-engine case —
  `xcodebuild … test` → **7 tests in 3 suites passing**; `… build` → **BUILD SUCCEEDED**;
  app launches without crashing.

**Half-finished / open**

- Start/stop still does not watch the child's exit (state can go stale if `serve` dies);
  worth addressing alongside T4.
- Menu-bar icon is still the placeholder SF Symbol (founder is producing the real template
  image — T4.3/T4.4). Graph embedding (T4.2), re-index (T4.1) and operator docs (T6.x) are
  untouched.

**Single next step**

- Phase 4 polish: re-index codebase-memory (T4.1) and embed the graph UI via `WKWebView` →
  `http://localhost:9749`, restyled to the palette (T4.2).

## Handoff — 2026-09-25 (icon Easter egg)

**Completed**

- **The "open and shut" Easter egg (T4.7).** All four of the founder's icons are held in one
  roster, `Support/IconRoster.swift` (`AppIcon` + `IconRoster.all` + a never-repeat
  `next(after:)`). The app wears one face at a time and rerolls to a **different** face every
  time the server starts or stops — never the one that just went away. The face shows on both
  surfaces: the menu-bar glyph and the popover header, and each face carries its own glow
  colour so the swap is unmistakable.
- **Plumbing.** `ServerController` owns `currentIcon` and advances it on genuine start/stop
  transitions (and on a vault/model switch, which restarts). The controller is hoisted into
  `SeaStarApp` so the `MenuBarExtra` glyph is state-driven (was a fixed `systemImage`), and
  the popover reads the same instance. New `Views/AppIconMark.swift` renders a face on either
  surface — exported artwork when present, placeholder symbol otherwise, template rendering
  for the menu bar.
- **Tests:** `IconRoster` (four distinct faces; a reroll never repeats the current face; a
  reroll with nothing showing still returns a face) plus the cockpit's opening face —
  `xcodebuild … test` → **11 tests in 4 suites passing**; `… build` → **BUILD SUCCEEDED**;
  app launches without crashing.

**Half-finished / open**

- Faces are **placeholder SF Symbols**. When the Icon Composer art lands, export the PNGs to
  `Assets.xcassets` and set `headerAsset`/`menuBarAsset` on each `IconRoster.all` entry —
  no view or controller change needed (spec T4.3/T4.4).
- Start/stop still does not watch the child's exit (state can go stale if `serve` dies).
- Graph embedding (T4.2), re-index (T4.1) and operator docs (T6.x) are untouched.
- Work is staged on `feat/macapp-cockpit` but **not committed**; no draft PR opened yet.

**Single next step**

- Founder drops the four real icons into `Assets.xcassets` and names them on the roster; then
  commit the icon work and open the draft PR.

## Handoff — 2026-09-25 (real faces + caustic shimmer)

**Completed**

- **Real art landed (T4.3/T4.4 cuts).** `Assets.xcassets` now ships eight imagesets — four
  `Face*Header` (40/80/120px, full detail) and four `Face*MenuBar` (18/36/54px, solid
  silhouette) — all black-ink-on-transparent with `template-rendering-intent: template` and
  `-strip`ped `graya` sources. `IconRoster.all` names them (`headerAsset` / `menuBarAsset`),
  so swapping art is a data change, not a view change.
- **`AppIconMark` reworked.** Both surfaces render `.template` (the header's black-on-clear
  art would be invisible on the near-black canvas otherwise, and the template gets tinted by
  the face's accent). Added a `size` parameter because raster art ignores `.font`; the
  header now frames the mark at `CockpitPopoverView.markSize` (26pt).
- **Header caustic shimmer (T4.5).** New stitchable shader `Shaders/Caustics.metal` (two
  drifting value-noise fields → a highlight gated by the artwork's alpha, so the silhouette
  never moves — only the light does) wrapped by `Views/CausticsEffect.swift`
  (`TimelineView(.animation)` + `.colorEffect`, disabled under **Reduce Motion**). Header-only.
- **Metal toolchain note.** `.metal` files need Xcode's separately-downloadable Metal
  toolchain; on a fresh machine `xcodebuild -downloadComponent MetalToolchain` first (this
  machine: build version 27A266a, `Status: installed`).
- **Verified:** `xcodegen generate` → `xcodebuild … build` → **BUILD SUCCEEDED**;
  `xcodebuild … test` → **11 tests in 4 suites passing**; `Assets.car` (40 KB) and
  `default.metallib` (69 KB) confirmed inside the bundle.

**Half-finished / open**

- The Icon Composer **`.icns` app icon (T4.4)** is still pending the founder's export — the
  header/menu-bar art is wired, but the bundle app icon has not been replaced.
- The shimmer and the header art have been **eyeballed and approved** by the founder (panel
  looks "fabulous"; colours "exceptional"). The menu-bar silhouette was re-cut: the first pass
  ran a morphology *Close* that rounded the concave notches and made the 8-point star read as a
  cog/sprocket. The cut now uses a hole-fill (`-threshold` → flood-fill border → replace holes)
  with no closing, which keeps the star points sharp. Source art is **8-pointed**, not a 5-arm
  sea star — worth knowing before anyone "fixes" the shape.
- **Multi-harness detection — done (was the "next real gap").** The engine's
  `detect_runtime()` (`src/sea_star/config.py`) used to probe `KNOWN_RUNTIMES` in order and
  **adopt the first that answered**, returning a single `(name, base_url, model)`. So if
  Osaurus (1337) was up it always won and shadowed oMLX/Ollama/LM Studio etc. — which is
  exactly why the panel showed `osaurus · foundation` instead of the model the founder was
  actually loading in oMLX. Now `probe_runtimes()` probes **every** live runtime concurrently
  (`asyncio.gather`, one `PROBE_TIMEOUT_SECONDS` budget) and returns a `RuntimeProbe` per live
  responder. `detect_runtime(probes=…)` and `load_config(probes=…)` reuse the survey;
  single-runtime machines are unchanged. The bridge emits `runtimes[]` (optional key;
  `schema_version` stays `1`), and the cockpit's Harness row is a pick-list when more than one
  is live.
- **Port sweep — done (the *real* cause of "Refresh missed my model").** The first-wins bug
  above was only half the story: `KNOWN_RUNTIMES` looks at oMLX on **8000**, but the founder
  runs it on **8009** (confirmed via `lsof` + `~/.omlx/settings.json`), and the same account
  runs a second copy on 8000 — harness ports are simply not fixed. `config.py` now has
  `scan_ports()` (known-harness ports first, then `EXTRA_SCAN_PORTS` like 8009/5000/9000) and
  `probe_runtimes()` sweeps them all, naming each responder by its self-reported `owned_by`
  when specific (`omlx`), else the port's known harness, else `"local"`; generic owners
  (`library`, `user` …) are dropped. `SEASTAR_SCAN_PORTS` overrides the set. Still local-only,
  same timeout. This is **not** a cache/network problem — it never was.
- Start/stop still does not watch the child's exit (state can go stale if `serve` dies).
- Graph embedding (T4.2), re-index (T4.1) and operator docs (T6.x) are untouched.
- Multi-harness + port-sweep work is **committed** on `feat/macapp-cockpit` (two commits) and
  pushed; **draft PR #2** is open at https://github.com/Roqett/Sea-Star/pull/2.

**Single next step**

- Founder's `.icns` export for T4.4 (the app icon is the last unwired piece), or a live
  run-through of the harness picker against 8009 to confirm the sweep names oMLX correctly;
  then fold the port-sweep commit into draft PR #2.

## Handoff — 2026-09-25 (app menu + settings + updates)

**Completed**

- **Right-click menu — the founder's "must have" (spec §8.6).** `MenuBarExtra` gives no
  right-click hook, so the shell was rebuilt on AppKit: new `@main enum SeaStarMain` starts
  `NSApplication` directly and hands to a new `App/AppDelegate.swift`, which owns the
  `NSStatusItem` and shows an `NSMenu` on right-click / ⌃-click — Check for Updates…,
  Settings… (⌘,), Help & Comments, Patchdog, a disabled version line, Quit Sea-Star (⌘Q).
  Left-click still opens the popover. The popover and settings are the *same* SwiftUI views,
  hosted in `NSPopover` / `NSHostingController`. `App/SeaStarApp.swift` (old `MenuBarExtra`
  shell) was deleted. New `Support/Links.swift` (all URLs) and `Support/AppInfo.swift`
  (bundled version/build).
- **Settings window (spec §8.4).** New `Views/SettingsView.swift`: engine resolution + path,
  a **searchable** scrolling vault list with Open folder… / Use detected vault, harness/model
  pickers, an inline update check, and links.
- **GitHub Releases update check (spec §8.5).** New `Services/UpdateChecker.swift` +
  pure `Version.isNewer` (dotted-number compare, leading `v` and ragged segments tolerated);
  offers the release page only when genuinely newer, says so plainly on failure.
- **Vault / model / panel fixes.** The vault row gained **Open folder…** (folder picker →
  `SEASTAR_VAULT`) and no longer greys out when a folder entry is reachable; the model row now
  follows the **selected harness** (`currentHarness.models`), so the oMLX-only Qwen model
  appears on switch; the popover's detail body **scrolls** (pinned header + controls).
- **Verified:** `xcodegen generate` → `xcodebuild … test` → **16 tests in 5 suites passing**;
  `… build` → **BUILD SUCCEEDED**.
- Updated `spec.md` (§4 AppKit host; new §8.1–§8.6), `CHANGELOG.md` and this file.

**Half-finished / open**

- The right-click menu, settings window and update alert have **compiled and are unit-tested
  but not yet eyeballed by the founder** in a running build — worth a live pass.
- `Patchdog` points at a **placeholder URL** (`github.com/Roqett/patchdog`) and the agent
  repo itself does not exist yet.
- Start/stop still does not watch the child's exit (state can go stale if `serve` dies).
- Graph embedding (T4.2), re-index (T4.1) and operator docs (T6.x) are untouched; `.icns`
  app icon (T4.4) still pending the founder.
- Not yet committed — the AppKit shell + settings + updates are staged on
  `feat/macapp-cockpit`.

**Single next step**

- Live run-through of the new build (right-click menu → Settings → Check for Updates), then
  commit the work and fold it into draft PR #2.

## Handoff — 2026-09-25 (cockpit strips, logs & the starfield)

**Done**

- **Start/Refresh de-capsuled (spec §8).** Removed the `GlassEffectContainer` pills; both are now
  plain SF Mono words, toned down, with **Start in the left corner and Refresh in the right** and
  a clean band of space above/below. A **blue-white nudibranch strip** frames that band.
- **Strips in the app (spec §7).** Three 3px ribbons added as imagesets (`NudiBlueWhite`,
  `NudiGreenOrange1/2`, `template-rendering-intent: original`) and wrapped in
  `Views/NudiStrip.swift` (`expands` = full-width rule vs. fixed stroke).
- **Logs (spec §8.8).** New `Services/LogStore.swift` (engine `stdout`/`stderr` → one file,
  prune-on-write, pure testable `retained`); collapsible cockpit **Logs** panel (strips top/bottom,
  SF Mono, blue ink, selectable); Settings → **Logs** retention picker (Forever/7/14/30, default
  14), entry count, **Clear now**, **Reveal in Finder**.
- **Entity graph (spec §8.7).** `Views/EntityGraphView.swift` + a **header** mode toggle (two SF
  Symbols — connected points / bulleted list — beside the "ready" pill and the gear; the choice is
  remembered in `UserDefaults` `SeaStar.cockpitMode`, and **first launch asks which reading to open
  with**). Glowing vault/harness/model nodes, rotated-strip connection, tap-to-select via the
  existing controller calls. **Animated**: per-node water drift, breathing glow, `caustics`
  highlight, and a connection ribbon that grows out of the vault on every active-harness change;
  all of it stills under Reduce Motion.
- **Logs toggle made discoverable.** The bare Logs word is now a disclosure row (chevron, terminal
  mark, live count, hover fill, Show/Hide tooltip).
- **Harness tip grows from the starfish (spec §8.7).** `Models/HarnessTips.swift` (pure, tested)
  decides one note: a **never-seen** harness → setting-up hint; else other vaults nearby →
  **wrong-vault** nudge; else a ready known harness → **"connected — *n* models"**. A note opens
  beside the active node and the starfish toggles expand/contract; a fresh hint's **Got it** records
  the harness in `UserDefaults` (`SeaStar.seenHarnesses`, keyed by endpoint) via `ServerController`.
- **Verified:** `xcodegen generate` → `xcodebuild … test` → **28 tests in 8 suites passing**;
  `… build` → **BUILD SUCCEEDED**. `uv run ruff check .` + `uv run pytest` → **51 passed**. Updated
  `spec.md` (§8.7, §8.8), `CHANGELOG.md` and this file.
- **Committed** on `feat/macapp-cockpit`: `12cdcaa` (AppKit shell + cockpit/strips/logs/graph),
  `776d1dd` (the moving starfield), `220d841` (the harness tip), plus the header mode-toggle slice.

**Half-finished / open**

- The **light-appearance** log ink (`logInkLight` / `logSurfaceLight`) is defined but the panel
  always uses the dark end, because the cockpit canvas is always the dark rockpool. Make the
  popover itself adaptive if the founder wants a true light mode.
- The **entity graph** is animated with a working tip note; the founder still has more coloured
  strip combinations to drop in, and offered to sample hex codes from the artwork for exact ink
  matching.
- **Deferred by the founder, not started:** the **MCP/browser probe** (fetch current info on the
  harness before chatting so the tip can be specific rather than generic) and optional **voice**
  that piggybacks the active harness.

**Single next step**

- Founder's look at the moving starfield, the starfish tip note, and the findable Logs row; then
  fold the branch into draft PR #2.

## Handoff — 2026-09-26 (popover fit, operator docs, shipped)

**Done**

- **Pushed the branch; draft PR #2 refreshed.** The four cockpit commits (AppKit shell,
  strips/logs/graph, starfield, harness tip) had never been pushed; they now are, and PR #2's
  body describes the whole engine + app change set. Checks re-run green first.
- **AGENTS.md committed — the no-go zone.** The founder's external drive (and any mirror of it)
  is off-limits to every agent: no reading, indexing, embedding, summarising or transmitting
  anything from it to a cloud or third-party model; local-only at most, and only on an explicit
  written ask.
- **The cockpit is capped to the screen (spec §8).** It was only ever as tall as its stacks summed
  to, so on a shorter display — or with Logs open — the bottom was clipped: exactly the "I can't
  see the whole thing" the founder hit. `CockpitPopoverView` now frames to
  `NSScreen.visibleFrame` less a margin and the middle section scrolls instead of spilling;
  `import AppKit` added. Verified: `xcodebuild … test` → **28 tests in 8 suites passing**.
- **Operator instructions written (T6.x).** New `docs/use-the-app.md` — a GUI-first track (the
  Cockpit) and a terminal-first track (the exact commands), with the parity table up top; wired
  into `docs/README.md` (door + map) and the root `README.md` (docs table). It also records that
  macOS builds do **not** have to be shell-first (§9.1) and that the `.icns` (T4.4) is
  unnecessary while the app is `LSUIElement` (no Dock presence).
- **CHANGELOG.md + this file** updated.

**Half-finished / open**

- **T4.2 (embed the graph web UI) is superseded** — the graph was built natively instead
  (`Views/EntityGraphView.swift`), so no `WKWebView` → `localhost:9749` embed is planned; confirm
  with the founder before closing it in `tasks.md`.
- **T4.1 re-index** (codebase-memory) and **T4.4 `.icns`** remain. The icon is now judged
  unnecessary (no Dock presence); the re-index is dev-machine hygiene, not a shippable change.
- **Onboarding shape — founder's new idea, not started.** The one-time Graph/List chooser should
  grow into proper on-boarding: the two readings shown as **two large, distinct panels** to pick
  between, with the header expanding to hold them; the header toggle takes over once a choice
  exists. Founder asked to keep it lightweight and do it **later**. Recorded, not built.
- The popover fit and the docs are **committed on `feat/macapp-cockpit`** and folded into PR #2.

**Single next step**

- Founder: relaunch the app to see the fit fix; then decide whether T4.2 closes as superseded and
  whether to schedule the two-panel onboarding.

## Handoff — 2026-09-26 (icon as template, light/dark, README)

**Done**

- **Menu bar now wears the detailed starfish (spec §7).** The glyph was a solid star; the four
  faces collapsed to **one cut each** (`IconRoster`'s single `asset`, the former `Face*Header`),
  rendered as a **template** on every surface. The system tints it, so it is white on a dark menu
  bar and black on a light one and the fine line art survives. The bare cut read as a snowflake,
  so `AppIconMark` now draws a **solid band partway out from the fuzzy centre** (a sea-star's
  body, ray tips free) on both the header and the menu bar — the menu bar via
  `AppIconMark.menuBarImage(for:)`. `AppDelegate.applyStatusIcon` now uses that helper instead of
  loading the raw asset.
- **Both panels gained light/dark mode; the starfield stays dark (spec §7).** `Palette.swift`
  rewritten into an **adaptive chrome** layer (`canvas`, `ink`, `inkMuted`, `logInk`, `logSurface`,
  via an `NSColor` dynamic provider on `bestMatch(.darkAqua/.aqua)`) plus a **fixed-dark `pool`**
  for the entity graph. `CockpitPopoverView` chrome renamed to the adaptive tokens; `EntityGraphView`
  switched to `pool` (its ink stays light on purpose). Verified by sampling both appearances with a
  throwaway `swiftc` program: canvas `#10131A`↔`#F7F3EC`, ink `#EDE3D2`↔`#1C1A17`, pool `#10131A` both.
- **Log strips inset (spec §8.8).** The blue-white nudibranch ribbons are pulled in from the panel
  edges and floated on the log ground, matching the Start/Refresh controls.
- **README polished.** Subtitle typo fixed, Local-first + MCP badges added (flat-square), a new
  **At a glance** section, page count corrected to five, founder's closing note centered — no facts
  or links changed.
- **CHANGELOG.md + this file** updated. Throwaway verification artifacts deleted.
- **Verified:** `xcodebuild … test` → **28 tests in 8 suites passing** (twice).

**Half-finished / open**

- **The old `Face*MenuBar` imagesets are kept on purpose.** `IconRoster` uses only the `Face*Header`
  cut now, so the `MenuBar` cuts are unreferenced — but the founder wants them filed as **potential
  tools** rather than pruned ("keep them because they're nice little files"). They stay in the
  catalog, unlinked, for later.
- **Onboarding shape — founder's idea, still not started** (two large Graph/List panels). Explicitly
  deferred to later.
- **Inverse (dark-on-light) starfield variant** — the founder floated it ("maybe an inverse one might
  look cool"), deferred to later.

**Single next step**

- Founder: relaunch to see the banded menu-bar starfish, the light/dark panels, and the larger
  starfield panel; then decide whether to schedule the two-panel onboarding.

---

## Handoff — 2026-09-26 (panel sizing, banded icon)

**Done**

- **The two readings got their own rooms (spec §8, §8.7).** The popover was a fixed 320pt column for
  both readings, which crowded the starfield. `CockpitPopoverView` now sizes by mode — **graph
  ~460 wide** (graph height = the body height), **list 340** — via `panelWidth` / `bodyHeight` /
  `graphHeight`, and `EntityGraphView` gained a `height` parameter. The rows are happy in the narrow
  column; the starfield gets the width for the right-edge harnesses and the height for the tip note.
- **The popover no longer clips itself (the founder's "still truncated").** The middle used a flexible
  `maxHeight`, which left the popover's preferred size *undecided*, so it opened undersized and cut off
  its own content (confirmed by screenshotting the live popover). It now gets a **concrete height**
  (`bodyHeight`, clamped only to keep the bottom on-screen) with the root's flexible `maxHeight`
  removed, so the fitting size is deterministic and it opens whole. The reading is only open for a
  moment, so it is allowed to be large.
- **The icon stopped reading as a snowflake (spec §7).** `AppIconMark` draws a **solid band partway
  out from the fuzzy centre** — a sea-star's body with the ray tips free, so it reads as neither a
  snowflake's spokes nor a cog's rim. The ratio was chosen by eye against a rendered set of
  alternatives: **`bandDiameter` 0.55, `bandWidth` 0.12** (thinner and the ring thins away at
  menu-bar sizes; wider or further out and it starts to read as a cog). Added
  `AppIconMark.menuBarImage(for:)` so the **menu bar** draws the same band as a template;
  `AppDelegate.applyStatusIcon` now calls it instead of loading the raw asset.
- **`AppDelegate.popoverSize`** (460×720) matches the graph default so there is no undersized flash
  before the hosting controller reports its real size.
- **Wording:** dropped the colour absolute from CHANGELOG/PROGRESS (UI absolutes are out).
- **`Face*MenuBar` imagesets kept** as potential tools (see above).

**Verified**

- `xcodebuild test` — 28 tests in 8 suites pass; `xcodebuild build` succeeds; app relaunched.
- The band was checked against the four faces in header-accent and menu-bar tints at 40/26/18pt
  (throwaway `iconpeek` preview under `~/Random_MCP/iconpeek`).

**Single next step**

- The founder judges the band on the live menu bar and popover.
