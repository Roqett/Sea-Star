# Progress

Live build state and session handoff. Read this before starting work; append a handoff
note at the end of every session.

## Current state

- **Version:** 0.1.0 (unreleased). Repo is **private** until built and tested.
- **Health:** `uv run ruff check .` clean; `uv run pytest` — 164 passing. App:
  `xcodebuild … test` — 95 Swift Testing cases passing (17 suites). Both re-run at session
  close 2026-10-06.
- **Foundation (`docs/foundation.md`, binding from 2026-09-28).** The lead clause is
  **"no name is ever a precondition"** — every known harness/runtime name is an *additive
  hint* that improves a label, and its absence may never reduce what is displayed. Carries
  the eight-rung **capability ladder** (declared → present → running → listening →
  self-describing → agent-aware → activity-aware → caller-attributed), the **degradation
  contract** ("show the highest rung reached, and show the rung"), **MCP as the generic
  adapter** (ask an unknown harness rather than know it), and a **symmetry clause** —
  anything Sea-Star can prove must be callable over MCP, not only visible in the app.
  Tier 1 (§1 values, §4 privacy) is the founder's alone to rewrite. Four items of known
  debt are logged *in* the document — most importantly that `harnesses.py` still gates
  visibility on a bundle-id allowlist and skips unknown apps entirely. `AGENTS.md` now
  points here; the repo front page is the shopfront, not the foundation.
- **Bridge:** `sea-star doctor --json` now emits the full §6 contract —
  `schema_version`, nested `vault {path, source, note_count, candidates}`, `mcp_clients[]`,
  and `runtimes[]` (one object per live harness). Always one JSON object, even on failure.
  `include` / `exclude` tool curation is wired through `config.py` → `mcp_client.py`.
  `server.state` is **still emitted but is misleading** and is no longer described here as
  part of the contract — see the 2026-10-01 handoff, "Stale `server.state`".
- **Cockpit (new):** the macOS menu-bar app exists under `macapp/` (XcodeGen + SwiftUI).
  It builds, launches, and its 83 Swift Testing cases pass (15 suites). Popover shows vault/harness/model
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
| Foundation | `docs/foundation.md` | **New** — the binding document. "No name is ever a precondition"; capability ladder, degradation contract, MCP-first. Binding from 2026-09-28. |
| Harness/app discovery | `src/sea_star/harnesses.py` | Partial — **violates foundation §1**: gates on `KNOWN_HARNESS_APPS` and skips unrecognised apps instead of showing them degraded. |
| Agent roster | `src/sea_star/agents.py` | New — per-harness agent/provider/model config discovery. Private prompts are never copied out. |
| Connection records | `src/sea_star/connections.py` | **New 2026-09-30** — `serve` records which host spawned it (`~/.seastar/clients/{pid}.json`, identity walked up 8 parent processes to the `.app`, derived fields only, dead pids pruned); doctor counts recorded hosts **active**, emits additive `mcp_clients[]`. Fixes the "TraeWork not active" structural bug (quick form of foundation §3). |
| Cockpit (mac app) | `macapp/` | **New** — XcodeGen project; **AppKit-hosted** SwiftUI (`SeaStarMain` → `AppDelegate`, `NSStatusItem` + `NSPopover`). `App/ Views/ Models/ Services/ Support/ Shaders/`; builds, launches, 29 Swift tests pass. Right-click app menu + Settings window + GitHub-Releases update check. Vault + model + harness pick-lists wired to `SEASTAR_VAULT`/`SEASTAR_MODEL`/`SEASTAR_BASE_URL`. Four-face icon roster rerolls on start/stop (T4.7); real T4.3/T4.4 cuts; header caustic shimmer (T4.5). Idle harnesses float by default (hidden-set preference, migrated off the old enabled-set key). |

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

## Handoff — 2026-09-26 (the server that never stayed up)

**Done**

- **Found the real reason "Start" never worked.** `sea-star serve` is a **stdio MCP server**: the
  instant its `stdin` reaches EOF it shuts down. `ServerController.startServer` built a `Process`
  but never set `standardInput`, so the child **inherited the app's own stdin — closed for a
  menu-bar app** — saw EOF, and exited in the same breath. Meanwhile `isServerRunning` stayed
  `true`, so the pill read **Running** while nothing was actually serving. This is the bug behind
  the founder's "it looks amazing, but it's still not actually working".
- **The fix (`ServerController`).** Hold a `Pipe` open as the child's stdin (`serveInput`), so the
  server stays genuinely alive; add a `terminationHandler` that clears `isServerRunning` /
  `serveProcess` / `serveInput` and logs `engine stopped` if the child ever dies on its own; release
  the pipe in `stopServer()`. State now tells the truth in both directions.
- **Proved the lifecycle both ways** (faithful to the app's exact invocation
  `.venv/bin/sea-star serve`): **stdin closed → exits in ~0s** (the bug); **stdin held open →
  still alive after 4s** (the fix). Reproduced headlessly while the Mac was locked.
- **One canonical run path.** New `script/build_and_run.sh` (kill → `xcodegen generate` →
  `xcodebuild -derivedDataPath build` → `open` the *fresh* bundle; modes
  `run`/`--debug`/`--logs`/`--telemetry`/`--verify`) plus `.codex/environments/environment.toml`
  wiring the Codex **Run** button to it. Removed the stale
  `~/Library/Developer/Xcode/DerivedData/SeaStar-…` bundle so the old binary can no longer be
  launched by accident.

**Verified**

- `./script/build_and_run.sh --verify` → **BUILD SUCCEEDED**, "OK: Sea-Star is running from
  `macapp/build/Build/Products/Debug/Sea-Star.app`".
- The **currently-running** bundle contains the fix: `nm`/`strings` on
  `Sea-Star.debug.dylib` show the `serveInput` property and the `engine stopped` string
  (binary built 14:40, after `ServerController.swift` 14:37).
- The panel renders correctly in both readings (graph: full starfield, tip inside the frame;
  list: rows hug content); the tip "Got it" settles to *"osaurus is connected — 1 model on
  offer."*; the log count updates on a refresh.
- `xcodebuild … test` → **28 tests in 8 suites pass**.

**Round-trip confirmed (screen unlocked).**

- Rebuilt with `./script/build_and_run.sh run` (BUILD SUCCEEDED), then drove the popover via
  System Events:
  - **Start** → a real `.venv/bin/sea-star serve` process appeared and **stayed alive** (PID
    47238; independently re-checked ~20s later — still running).
  - **Stop** → process **gone**, log `engine stopped by request`.
  - **Start** again → PID 47288 alive 5s+, log `engine started · sea-star`.
- The two stop paths are now distinguishable in the log: `terminationHandler` writes
  **`engine exited on its own · <reason> <status>`**, `stopServer()` writes
  **`engine stopped by request`** — so a future spontaneous exit names itself (and its exit
  code/signal) instead of hiding behind the same line.
- Isolation proof of the spawn pattern: an app-exact probe (`script/serve_spawn_probe.swift` —
  environment merge + three pipes + readability handlers + held stdin) keeps the child alive a
  full 15s, matching the live app. The earlier one-off ~4s exit did not reproduce on a clean,
  settled app and is now instrumented to name itself if it recurs.

**Open**

- Commit the `ServerController` lifecycle fix + `script/build_and_run.sh` +
  `.codex/environments/environment.toml` + docs (PROGRESS/spec) to PR #2.

---

## Handoff — 2026-09-28 (the foundation, and the thread worth nipping)

**Done**

- **Named the thread, then wrote it down as law (`docs/foundation.md`, new).** The founder's
  read was right and it is now binding rather than tribal knowledge: Sea-Star had been
  learning *products* (Trae, Osaurus, oMLX) where it should have been learning
  *capabilities*. The lead clause is **"no name is ever a precondition"** — every known
  name is a *hint* that improves a label, and its absence may never reduce what is
  displayed. A registry of the top ten harnesses is therefore an **upgrade, not a
  permission**: if the list is a year stale, the product must be no worse off than before
  the list existed. The document carries a three-question **test** for any name-keyed
  behaviour — does removing the name make things *worse* (fine) or *blank* (a gate, a bug)?
- **The capability ladder** replaces "which harness is this?" with "what can this thing
  prove?", asked in a fixed order and stopping at the first yes: **declared → present →
  running → listening → self-describing → agent-aware → activity-aware → caller-attributed**.
  Rungs 0–4 are vendor-neutral and must stay that way — they are the reason Sea-Star works
  with a runtime released last month. Rungs 5–7 are where adapters legitimately live.
- **The degradation contract: show the highest rung reached, and show the rung.** This is
  the clause that makes the whole thing honest, and it lines up exactly with the evidence
  discipline the panel design was already built on: `Configured`, `Reachable`, `Active`
  and `Last reported` are different facts and may never be collapsed. A configured route is
  not a running model; a loaded model is not an active request; a healthy endpoint does not
  prove anyone is using it, and never names the caller.
- **MCP as the generic adapter, plus a symmetry clause.** Because MCP is a standard rather
  than a product, an unknown harness can be *asked* rather than *known* — that is the
  mechanism that makes degradation cheap, and the reason "a new harness appeared" is never
  answered with a longer list. Symmetry: if Sea-Star can prove a fact, that fact must be
  callable over MCP too, which is why "registered in Osaurus" and "useful to Osaurus" are
  two different milestones.
- **Tiers, so the rules cannot all be renegotiated at once.** Tier 1 (§1 values, §4
  privacy) is the founder's alone to rewrite. Tier 2 (ladder, degradation, MCP-first) is
  a design bet that can be pivoted with reasons. A spine that survives a real pivot
  unchanged was probably never tested — friction is a signal to amend, not to argue.
- **Four items of known debt are logged *inside* the document** so the gap is visible
  rather than rediscovered: `harnesses.py` still gates on a bundle-id allowlist and skips
  unrecognised apps entirely; no MCP activity probe exists; cockpit findings are not yet
  MCP tools; rung 7 has no instrumentation.
- **Wired in as the source of truth.** `AGENTS.md` now points at `docs/foundation.md`
  (it previously said `README.md` "until `docs/` exists") and names the clause as a
  tripwire; `docs/README.md` indexes it for developers and agents and states plainly that
  the repo front page is the shopfront, not the foundation.
- **Two UI changes, both from "know what's running without hunting for it".** The graph
  state card was bound to `selected ?? hovered`, so with neither set there was no card at
  all and the popover opened looking empty — `subject` now falls back to the active
  harness, with click and hover still overriding. Idle harnesses now float **by default**:
  the preference inverted from an *enabled* set to a *hidden* set (`SeaStar.latentHarnesses`
  → `SeaStar.latentHarnessesOff`, old key removed on launch so it cannot linger), because
  an app on the disk is somewhere this machine *could* work and the founder should take
  things off the graph rather than switch them on.

**Verified**

- `xcodebuild … test` → **29 Swift Testing cases in 8 suites pass** (includes the new
  `latentHarnessesDefaultToVisible` regression covering on-by-default *and* stay-off).
- `uv run pytest` → **76 passing**; `uv run ruff check .` clean. (Both counts were stale
  in this file — 28 and 51 — and are now corrected above.)

**Open — carry into the next session**

- **The debt is the work.** §1 of the foundation is currently *violated* by
  `harnesses.py`: an app outside `KNOWN_HARNESS_APPS` is `continue`d, i.e. invisible
  rather than degraded. Replacing that gate with a rung-1/2 path for unrecognised apps is
  the single highest-value item here, because until it lands the document is a promise the
  code does not keep.
- **The redesigned text panel is agreed but unbuilt** — `Vault / Harness / Agent /
  Inference` replacing today's `Vault / Harness / Model`, with `Working now` and
  `Configured` as separate sections. Note the ontology reason: the Osaurus URL shown in
  today's `Harness` row is a *server endpoint*, which is exactly the collapse the
  `Agent` / `Inference` split exists to fix.
- **Telemetry needs reconciling with Tier 1 before any continuous collection.** The
  foundation's §4 keeps "no telemetry, no background monitoring", and activity records are
  scoped to *who / what route / when / how we know* — never *what was said*. Any activity
  stream has to be built inside that envelope, or the founder amends §4 explicitly.
- `.trae/specs/mac-app/spec.md` has not yet been amended for either the foundation or the
  new panel ontology.

**Single next step**

- Founder reads `docs/foundation.md` and confirms Tier 1 is worded as he means it; then
  take debt item 1 (`harnesses.py`) and make an unknown app visible, since that is the
  clause the code most clearly breaks.

## Handoff — 2026-09-28 (late) (the history gap, and the panel decision)

**Why this session existed**

The founder reopened a long session cold and asked where it actually ended. The honest
answer was: **the git history and the written history disagreed**, in both directions.

- **Two commits shipped with no changelog entry at all** — `f427d37` (the star-shaped
  tactile canvas) and `74f63b9` (detail card + mouse gestures). They were pushed, so the
  changelog described a *smaller product than the one that had actually shipped*.
- **A large body of work was in the working tree and never committed** — 17 modified files
  and 7 new ones, including the entire graph evolution (`EntityGraphView.swift` had gone
  800 → 1,342 lines), `GrainOverlay.swift`, `SeaStarShape`, and two new engine modules.

So the record was wrong in both directions at once, which is the worst case: a changelog
that both over- and under-claims. This session closed that gap, and then *decided* the panel
direction the founder had asked for — the decision is written up below, the panel itself is
not built yet.

**Done — the record, made honest**

- **Backfilled the two undocumented commits** as a dated **2026-09-26** entry, explicitly
  labelled a backfill. Every bullet is tagged with the commit that contains it (`f427d37` /
  `74f63b9`) and the entry states, in its own words, that it claims **only** those commits'
  contents. An earlier draft of this entry wrongly attributed the *uncommitted* `SeaStarShape`
  / `GrainOverlay` / agent-node work to those two commits; that was corrected before commit.
  The original commits are untouched, per the append-only rule.
- **Wrote up the uncommitted session** as a 2026-09-28 entry covering what is actually in
  the tree: the two new engine modules and the bridge keys they feed, the sea-star anatomy
  redraw, the living water, and the graph learning the `agent` / `latent` node kinds.
- **Found a third gap while checking**: the 2026-09-25 entry documents the port sweep as
  living in `config.py` — true — but `src/sea_star/harnesses.py` (latent harness discovery)
  **was never committed at all** and had no entry describing it. Now written up.

**The ontology decision (made here, deliberately not punted)**

The last session left an open question and floated it back at the founder: when `Agent`
splits out of the old `Harness` row, does the harness row become "the app you talk to" with
selection moving to `Agent`, or does it keep a picker? The founder's answer was that this
is the assistant's job to decide. **Decision: the Harness row keeps its picker.**

Reasoning, for whoever picks this up:

- The picker is not the problem. **The URL in the harness row is the problem.** Today the
  row reads `osaurus · http://127.0.0.1:1337/v1` — an *identity* and an *endpoint* collapsed
  into one string, so the row answers two different questions at once and neither cleanly.
- Switching harness is a **real, working, already-shipped action** (it pins
  `SEASTAR_BASE_URL` + `SEASTAR_RUNTIME` and clears the model override, because the old
  model may not exist on the new endpoint). Moving that selection onto the `Agent` row would
  delete a working control to fix a wording problem. That is the wrong trade.
- So the fix is a **move, not a removal**: the endpoint descends to the new `Inference` row,
  where it belongs, and `Harness` keeps only the name of the app you are talking to. The
  picker stays exactly where it is and keeps working.
- `Agent` is therefore **additive** — a persona inside the harness, shown when one exists
  and degrading honestly (rung shown, never a rung claimed) when the harness has none.

Resulting row set: **Vault** (where the notes are) → **Harness** (which app answers; picker
kept) → **Agent** (which persona inside it) → **Inference** (the endpoint *and* the model,
the two things that used to be smeared together). `Working now` sits underneath as its own
section, carrying only observed facts.

**Also this session — nothing built yet, and this is deliberate**

The founder gave the direction for the next stretch, and it is recorded here so the next
session does not have to be told again. **None of the following is built.** It is the plan,
not a report:

- **The panel gets built as two comparable variants** rather than one, at the founder's
  request, so the layout can be judged by looking rather than by argument. Both will carry
  the same four rows and the same `Working now` list; they will differ in presentation only,
  with a header toggle that switches between them and remembers the choice.
- **`Working now` will be observation-only.** It shows what the engine can *prove right now*
  — server state, a harness answering, the model last reported — and each line will say how
  it is known. It will show **no prompts, no model output, no tool arguments**: that is the
  foundation's Tier 1 privacy envelope, and the activity-event stream is what will later add
  real events *inside* that envelope.
- **The 3D graph is wanted and approved** (founder, 2026-09-28), to be built *after* the
  panel. His reasoning is sound and is recorded as the justification to build on: this graph
  has ~10 nodes, not the thousands that make 3D unreadable, so occlusion and projection are
  not the blocker they would be for a `codebase-memory`-scale graph. He also judged the
  binary cost acceptable — SceneKit is a system framework, so it adds no meaningful weight.
  Readability must be protected by keeping hover text and click inspection on every node and
  honouring Reduce Motion.
- **Live/used entities will carry the orange-green nudibranch bars**, animated. The honest
  limit to build in from the start: with no activity probe yet, "live" can only mean
  *answering on a port* (observed) — **not** "recently used by a person" (unobserved). The
  bar may only take the stronger claim once the activity stream exists.

**Verified**

- `uv run pytest` → **76 passed**; `uv run ruff check .` → clean.
- `xcodegen generate` then `xcodebuild … build` → **BUILD SUCCEEDED**;
  `xcodebuild … test` → **29 Swift Testing cases in 8 suites passed**.
- (The XCTest layer prints `Executed 0 tests` — that is expected; the suite is Swift Testing,
  not XCTest. The 29-case figure above is the real one.)

**Open — carry into the next session**

- **Build the panel**: the four rows above, `Working now`, and the A/B toggle. This is the
  founder's stated next piece of product work and supersedes the older "repair unknown-harness
  discovery first" single-next-step, which the founder explicitly redirected.
- **The activity-event stream is the piece after the panel**, and the panel is being built to
  receive it. Until then `Working now` is limited to state the engine already knows.
- **`harnesses.py` still violates foundation §1.** Unchanged by this session and still the
  clearest gap between what the document promises and what the code keeps. The new panel is
  where a degraded row would become visible, so it is cheap to fix alongside it.
- **`.trae/specs/mac-app/spec.md` is still the old panel** (`Vault / Harness / Model / Go`).
  It needs amending for the foundation, the four-row ontology, `Working now` and the 3D
  graph — the spec is the implementation contract and is behind the code.
- **Telemetry must be reconciled with Tier 1 before any continuous collection.** The
  foundation's §4 keeps "no telemetry, no background monitoring". Activity records are scoped
  to *who / what route / when / how we know* — never *what was said*. Any activity stream must
  be built inside that envelope, or the founder amends §4 explicitly.

**Single next step**

- Build the panel: `Vault / Harness / Agent / Inference` with `Working now`, in two
  comparable variants behind a toggle.

## Handoff — 2026-09-30 (two-window stocktake, legibility, animation gate)

**Why this session existed**

The founder called the cockpit "a cascading cluster of misunderstanding": he had asked to
compare two *text* structures, agreed in passing to also show both *graph* types, and ended
up with both-of-each in both windows. He asked for a coherent stocktake and game plan for
both instances — covering idle 2D nodes that hid their kind, a 3D room that was "blown
out" beside the flat star shells, animation burning CPU while nobody was watching,
liveness bars too subtle to notice, and input (hover, keyboard, voice) planned flexibly
for down the track. This session made that game plan real in code, tests, and docs, and
supersedes the previous note's "Single next step — build the panel": the panel is built.

**Done — the game plan, executed**

- **Axes settled (D-002):** text window = `SeaStar.panelLayout` Stack (default) / Chain /
  Both, 360pt (660pt Both); graph window = `SeaStar.graphDepth` Flat (default) / Deep /
  Both, 600pt/960pt wide, 560pt/600pt tall. Keys independent; comparison opt-in per
  window; stored prefs reset so the founder lands on flat + stack.
- **Text-window duplication pruned:** endpoint prints once (under *Inference*; the
  Working-now band keeps it as a `.help` string only), the redundant liveness word is off
  the row, header bar tightened 555→54pt.
- **2D identity:** nodes colour-coded by kind (teal / electric blue / neon green / orange)
  with a deterministic per-id hue shift so each kind is a genre; glow only when active or
  selected (dim breath when live, plain when idle); hover readout card names every node.
- **3D legibility:** bloom/emission/additive glyphs pulled back, motes 0.30→0.20, labels
  readable, camera home brought closer (0, 70, 240) — `poolFitsTheOpeningView` passes.
- **Animation scoped to visibility:** `SeaStar.cockpitOpen` environment (default false)
  written by the popover delegate, gating caustics, grain, the 2D timeline, SceneKit
  `isPlaying`, and the liveness drift. Server/MCP untouched — connections stay up when
  closed ("They close it, it shuts, and the MCP connections maintain").
- **Liveness bars legible:** orange/green active-connection strip at scale ×2 / 8pt sweep,
  no new timers; blue-white remains the resting strip everywhere else.
- **Engine roster:** `displayName` fallback, default-agent (the orchestrator) ordered
  first, `AgentRoster.source` reports the owning harness.
- **Docs:** spec §8 and §8.7 amended to the real panel, both axes, the colour/glow/hover
  rules, the 3D sibling, the animation gate and the input roadmap; DECISIONS **D-002**;
  CHANGELOG entry dated 2026-09-30; this handoff.

**Verified**

- `xcodegen generate` then `xcodebuild -project SeaStar.xcodeproj -scheme SeaStar
  -configuration Debug build` → **BUILD SUCCEEDED**.
- `xcodebuild … test` → **68 Swift Testing cases in 13 suites passed**. (The XCTest layer
  prints `Executed 0 tests` — expected; the suite is Swift Testing. 68 is the real
  figure.)
- `uv run pytest -q` → **84 passed in 0.47s**; `uv run ruff check .` → clean.
- Release bundle **4.4MB** vs the 3.6MB baseline; Resources unchanged at 136KB — the
  growth is compiled 3D code only.
- App relaunched live: pid **15130**.

**Open — carry into the next session**

- **The activity-event stream is next in line** (unchanged from the previous note):
  `Working now` and the glow still rest on endpoint probes, not usage. Build it inside the
  telemetry envelope — *who / what route / when / how we know*, never *what was said* — or
  the founder amends foundation §4 explicitly first.
- **`harnesses.py` still violates foundation §1.** Still the clearest gap between the
  document and the code; the four-row panel is now where a degraded row becomes visible,
  so it is cheap to fix alongside.
- **Voice + keyboard input are roadmap only** (spec §8.7): hover-first is shipped;
  "cycle through the models on the selected server" by key or voice is not built.
- **Brighter orange/green strip variants** were promised by the founder for graph active
  connections — art swap only; the amplitude rule stays (D-002).
- **Stray `plain`** (a 524KB `sample` CPU dump) sits untracked at the repo root — delete
  or move it out of the tree; it must not be committed.
- **Telemetry must be reconciled with Tier 1** before any continuous collection (unchanged).

**Single next step**

- Build the activity-event stream — *who / what route / when / how we know*, never *what
  was said* — inside foundation §4's envelope, so `Working now` and the graph's glow can
  rest on evidence instead of endpoints. Voice/keyboard model-cycling rides after it.

## Handoff — 2026-09-30 (connectors must connect)

**Why this session existed**

The founder sent a screenshot of the 2D graph in focus mode: the strips were "stylistically
cool but I would like it to actually look more functionally cool where the actual connectors
connect and don't go through to oblivion or to wide space. So all connecting graphics have
to actually connect to something." Before the pending push of 7828ada, fix it.

**Diagnosis (measured, not guessed)**

- `NudiBlueWhite` art is **743×3px**; `NudiGreenOrange1` is **375×3px** (1x universal).
- `NudiStrip`'s old body ended `.frame(height:).frame(maxWidth: expands ? .infinity : nil)`
  — with `maxWidth: nil` the caller's `.frame(width: length)` proposal never reached the
  Image, so it sized from native aspect: **~495pt wide at 2pt tall** regardless of the
  requested length. Each focus-edge strip overshot its node *and* the centre → rays to
  oblivion. Spec §8.7 already promised "fixed length"; the code silently violated it.
- `starBackdrop`'s hairlines are pinned to the *resting* star geometry, but focus mode
  rearranges nodes — so rays pointed at empty space and radiated from the focused node to
  non-neighbours (implying edges that don't exist).

**Done**

- `NudiStrip` branches: `expands == true` keeps the old fill behaviour; `expands == false`
  drops `.aspectRatio(.fill)` so the image honours the caller's width exactly; both paths
  `.clipped()`. Fixes the graph's connection strip, every focus edge, and `ChainLink`'s 18pt
  rule in the chain panel — one fix, three surfaces.
- `starBackdrop(in:)` in `pool(at:)` now carries `.opacity(focused == nil ? 1 : 0)` — the
  decorative star dissolves on focus (existing spring on `value: focused`) and returns on
  unfocus; in focus the only lines are real node→node edges.

**Verified**

- `xcodebuild -project SeaStar.xcodeproj -scheme SeaStar -destination 'macOS' test` →
  **68 tests in 13 suites passed**, TEST EXECUTE SUCCEEDED (pre-existing warnings only).
- Relaunched: the bundle is **`Sea-Star.app`** (hyphenated) under
  `DerivedData/…/Build/Products/Debug/` — `pkill -x Sea-Star; open …/Sea-Star.app`.
  `cockpitOpen` never auto-opens; the founder clicks the status item.

**Docs**

- CHANGELOG 2026-09-30 entry gained the connector bullet; spec §8.7 now records the
  terminate-on-a-node rule and the focus-mode backdrop stand-down; this handoff.

**Open / single next step** — unchanged from the note above: the activity-event stream;
`harnesses.py` §1 debt; voice/keyboard roadmap; brighter strip art; stray `plain` dump;
telemetry vs Tier 1. Push/merge of 7828ada + this fix still awaits explicit approval.

## Founder notes — 2026-09-30 (review-pass observations — HOLD, discuss before building)

Recorded during the start of the founder's methodical feature-by-feature review. These are
**notes, not work items yet** — he asked for them logged and left alone until the pass
produces the full picture.

1. **Plain-language MCP panels (docs).** The founder hit Atomic Chat's *Add MCP Server*
   panel (single Command box, `npx …` placeholder) and couldn't map it to our docs.
   `connect.md` speaks JSON `command`/`args`; hosts like this want **one line**. Needs a
   dummies-level section: what each field means, the exact line to paste
   (`uv --directory <abs path> run sea-star serve`), and no assumption that the reader
   uses a terminal or has `uv`. Wording rule: no jargon — he didn't know what a "smoke
   test" was; explain as if for dummies.
2. **Nobody has seen the tools used for real.** He has only ever seen Sea-Star *connect*,
   never *do* anything — "later we're gonna have to describe to people how an agent
   actually uses these tools." Most harnesses ship near-built-in Obsidian connections, so
   ours is a sidecar; docs/`connect.md` §"What to say to the agents" exists but has never
   been exercised end-to-end in front of him. Needs a worked, real example before any
   marketing-style claims.
3. **Primary-view decluttering rule (new, not yet discussed or spec'd).** "Actual models
   not being used in a server should only be visible in the zoom view unless it's actually
   active. The primary view needs to be as uncluttered as possible — only primary
   harnesses, servers, potentially MCPs active if possible." Hold for a design discussion
   before touching spec §8 or the graph.
4. **Carried holds** (from earlier today, still no fixes): always-visible blue latent vault
   line (latent when disconnected, live when connected, in every panel); `harnesses.py`
   allowlist debt (stale Osiris shown active, Atomic Chat undetected); docs/README naming
   neutrality scrub ("down the track", names only as explicit examples).
5. **3D direction — `3d-force-graph` as a hidden canvas (discussed, not yet decided).**
   The founder asked whether the web-borne `3d-force-graph` (three.js wrapper — the
   little package the rest of the industry copies) could live in our panel "just as like a
   canvas so that yes it's web originated but you wouldn't know." It can: a chromeless
   `WKWebView` hosting a **local bundled page** (no network), fed the same
   `EntityGraphModel` JSON, background painted to match the starfield — a **third
   renderer** over the same renderer-independent model. Costs to weigh before building:
   a few MB of bundle (spec's size gate — measure it), Swift↔page glue for
   hover/click/focus, Reduce Motion (no auto-spin). Would replace the hand-built SceneKit
    `GraphSceneView`, not sit beside it. Follow-up from the founder: could we then use
    *any* browser-based graph, "including the codebase-memory version"? Distinction
    recorded: a rendering **library** (3d-force-graph) is a dumb canvas we feed our own
    model into — clean, ours; a whole **application** (codebase-memory's explorer) expects
    its own backend/API/data shape, so embedding it means running their engine alongside
    ours (or maintaining an adapter), plus a license check and their update schedule.
    Sweet spot: same ingredient, our data.
6. **The orange/green nudi strips in the panels are "just sitting there doing nothing."**
   Investigation only — no fix until he says so. What they are: the two `LivenessBar`s in
   the text panel's *Working now* section — the header bar (`CockpitPanel.swift:555`,
   live = doctor `ready`) and the observation row (`CockpitPanel.swift:638`, live =
   server running or ready); graph nodes reuse the same component
   (`EntityGraphView.swift:895`, shown only when live). Design: vivid orange→green with a
   slow gradient crawl when live, grey and still when idle; motion additionally gated on
   the popover being open (`SeaStar.cockpitOpen`, default false, written by
   `popoverDidShow`/`popoverDidClose`) and on Reduce Motion (spec D-002 — "no signal means
   still, which is the safe failure"). Findings: (a) engine is genuinely live
   (`doctor ready:true`, `sea-star serve` running) so both bars should be in their vivid,
   moving state; (b) the running build (09:49 binary, launched 09:56) **does** contain the
   gate code — an earlier scare that the key string was missing from the binary was a
   false alarm caused by grepping the 40 KB launcher stub instead of
   `Sea-Star.debug.dylib`, where Debug builds keep all app code; (c) Reduce Motion is
   **off** (no `reduceMotion` key in `com.apple.universalaccess.plist` — never toggled);
   (d) `SeaStar.cockpitOpen` has never been written to any defaults domain, but the app
   was relaunched at 09:56 and the popover may simply not have been opened since — a
   15-minute passive watch (`/tmp/seastar_gate_watch.log`, started 12:33) logs the key and
   `cockpitMode` every 2 s while he clicks, to see whether opening the popover turns the
   signal on. If the signal works, the fallback explanation is the crawl itself: the sweep
   is only 8 points of travel, and "liveness bars too subtle to notice" was his complaint
   in the previous session too.
   **Root cause found (watch log + AppKit header, 12:33–12:58) — still report-only, no
   fix until he says go.** The watch log's 449 lines all read `cockpitOpen=absent
   cockpitMode=graph`, yet by 12:58 the live defaults show `cockpitMode = "list"`: he is
   clicking, and `@AppStorage` writes work — the open flag simply never fires. Cause:
   `NSPopoverDelegate` is declared in the SDK header as
   `- (void)popoverDidShow:(NSNotification *)notification` (same for willShow/willClose/
   didClose), but `AppDelegate.swift:92–98` implements `popoverDidShow(_ popover: NSPopover)`
   / `popoverDidClose(_ popover: NSPopover)`. Wrong parameter type → the ObjC selector never
   matches → AppKit never calls them → `SeaStar.cockpitOpen` is never written →
   `LivenessBar`'s `isOpen` gate stays false forever → crawl permanently off (D-002's
   "no signal means still" safe-failure doing exactly what it says, with a signal that can
   never arrive). Fix location when approved: the two delegate methods (or an explicit
   write in `togglePopover`, the single `popover.show` call site at `AppDelegate.swift:87`).

## Handoff — 2026-09-30 (session close — the structural fix landed, everything else listed)

**Why this session existed**

The founder's structural complaint: *"I just added TraeWork to it and it's not coming up as
active and you are."* Plus the session-close directive: finish what can finish now, then
leave a list that loses nothing for the new session. (He also suggested compaction — safe
once this section is on disk; it is a client-side button.)

**Root cause (found and fixed)**

The doctor decided "active vs latent" purely from **port probes**. TraeWork attaches over
**stdio** and never answers a port, so it was *structurally incapable* of looking active —
it would show as latent while genuinely connected. The approved quick fix is foundation
§3's "ask, don't guess" in miniature: **connection records** instead of the full §3 build.

**Done — engine (all live-proven)**

- New `src/sea_star/connections.py`: `serve` writes `~/.seastar/clients/{pid}.json` on
  start, clears it on exit. Identity = walk ≤8 parent processes to an absolute `.app`
  path matched against the bundle-id allowlist; fallback nearest executable basename.
  Stores **derived fields only** (name/bundle_id/app_path) — never raw `ps` command
  lines (they can contain shell exports/tokens). Dead pids are pruned on read, so a crash
  can never leave a ghost. Entirely best-effort: recording must never fail `serve`.
  Override dir: `SEASTAR_CLIENTS_DIR` (used by tests).
- `src/sea_star/cli.py`: doctor's `active` set now unions recorded client names → a
  connected TraeWork leaves `latent_harnesses[]`; new additive bridge key
  `mcp_clients[]` (`name`, `bundle_id`, `pid`, `started_at`); human doctor prints
  `Connected: <names>`; `serve` wraps `record_client()` / `finally: clear_client()`.
- Tests: `tests/test_connections.py` (new) + `tests/test_cli.py` additions, including
  `test_doctor_json_counts_an_attached_host_as_active`.
- Live proof: `doctor --json` showed both serves under `mcp_clients` —
  `{"name": "Sea-Star", "bundle_id": "UpPeriscope.Sea-Star", "pid": 30999}` (the
  cockpit's own) and `{"name": "TraeWork", "bundle_id": "com.trae.solo.app", "pid":
  31147}` — and TraeWork was gone from the latent list.
- Gotcha already paid for: parent command lines may merely *mention* an app
  (`source '/Applications/X.app'`), so app-path extraction is a delimiter-aware regex
  with a lookahead rejecting letters **and** dots — not a naive `.*?\.app`.

**Done — cockpit (decode + surface)**

The fix created a display gap: a connected TraeWork leaves both the popover's latent list
*and* the graph (latent nodes are idle-only), so it would appear **nowhere**. Closed in
the place with the right meaning — the **Working-now band** ("what's happening right
now"):
- `DoctorReport.swift`: new `McpClientInfo` struct, optional `mcpClients` field keyed
  `mcp_clients`, `attachedMcpClients` computed (`?? []`). The only construction path is
  the decoder, so the new field is contract-safe; an older engine yields an empty list,
  never an invented host.
- `Strings.swift`: `WorkingNow.host` / `.hostDetail` ("stdio connection record") /
  `.evidenceMcp`.
- `CockpitPanel.swift` (`WorkingNowBand`): a live **Host** row (all attached names) when
  `attachedHosts` is non-empty; the evidence line became a computed four-state switch —
  probe only / probe+record / record only / none — because a port probe and a connection
  record are *different proofs of different things* and the line must say which it stands
  on.
- `DoctorReportTests.swift`: 2 new decode tests (with and without the key).
- Spec §6 rules honoured: additive-only, stable keys, `schema_version` unchanged.

**Done — wrap-up items approved ("All four items")**

- The `plain` stray dump is **deleted** (524,945 bytes). Rule stands: never commit dumps.
- Full suites green: **97 pytest** + `ruff check .` clean; **70 Swift tests in 13
  suites**, TEST SUCCEEDED.
- CHANGELOG's 2026-09-30 entry gained the structural-fix bullet; verified numbers updated.
- Computer-use / permission probes (his extra ask) — findings at the bottom of this note.

**Not done in code, deliberately**

- The running cockpit binary predates these Swift changes. Relaunch when he's not
  mid-review: `pkill -x Sea-Star; open <DerivedData>/Build/Products/Debug/Sea-Star.app`
  (`script/build_and_run.sh` does the full rebuild). Then the Host row appears live.
- Nothing committed this session — see git state below; commits need his go (and 7828ada
  / 1216c7a still await explicit push approval).

**OPEN — complete list for the new session (start here)**

1. **Push / publish gate.** `7828ada` + `1216c7a` on `feat/macapp-cockpit` (plus all
   uncommitted work below) await **explicit approval** — never push/merge without it.
   Stale GitHub copy: the port-8009 scan was never published; the repo is still private
   ("publish as work in progress, hours away" was the founder's framing — his call).
2. **Commit decision for this session's work** (engine + cockpit + docs above) — single
   commit or split; don't touch the two awaiting-approval commits' history.
   **Git state at session close (2026-09-30):** branch `feat/macapp-cockpit`, **ahead 5**
   of `origin`; modified: `CHANGELOG.md`, `docs/PROGRESS.md`, `macapp/SeaStar/Models/
   DoctorReport.swift`, `macapp/SeaStar/Support/Strings.swift`, `macapp/SeaStar/Views/
   CockpitPanel.swift`, `macapp/SeaStarTests/DoctorReportTests.swift`,
   `src/sea_star/cli.py`, `src/sea_star/harnesses.py`, `tests/test_cli.py`; untracked:
   `src/sea_star/connections.py`, `tests/test_connections.py`. `plain` deleted (was
   untracked, so it never reached git history).
3. **HOLD ledger — Founder notes 1–6 above: report-only until he says go.** Short form:
   (1) one-line plain-language MCP paste instructions for hosts like Atomic Chat;
   (2) a worked real example of an agent *using* the tools end-to-end (never seen);
   (3) primary-view declutter rule — design chat before any spec §8/graph change;
   (4) carried holds: always-visible blue latent vault line, `harnesses.py` allowlist
   debt (stale Osiris shown active, Atomic Chat undetected), docs/README naming
   neutrality scrub; (5) `3d-force-graph` as a hidden canvas — decision pending, library
   vs whole-application distinction recorded; (6) nudi/liveness bars — root cause found
   (`NSPopoverDelegate` wrong signature, `AppDelegate.swift:92–98`), fix location noted,
   **still report-only**.
4. **Foundation §3 full build** (this session did only the quick connection-record form):
   MCP **symmetry clause** (anything provable must be callable over MCP — `mcp_clients`
   is currently doctor/cockpit-only), allowlist debt in `harnesses.py`, rung-7
   instrumentation (activity-aware = the activity-event stream), plus the four logged
   debts in `foundation.md`.
5. **Connected hosts as graph nodes (design question).** The graph has no node kind for
   a stdio-connected host; latent nodes are idle-only, so a connected TraeWork now
   surfaces *only* in the Working-now band. Decide whether/where it reappears in the
   graph — and reconcile with founder note 3 (decluttering).
6. **Duplicate `serve` processes to reconcile (needs his OK before killing anything):**
   Atomic Chat pid 22011, TRAE Helper pid 30516, cockpit pid 30999. Also: any host whose
   `serve` predates this fix records nothing — TraeWork must **reconnect** (restart its
   serve) for its record to appear; the pid 31147 proof was a fresh spawn.
7. **Chronicle question (he asked, unanswered).** It samples on ~30s activity-gated
   ticks, so a 3-second glance can be missed. `dynamicCaptureScheduleV1` suggests the
   interval may be configurable — next session: find out whether ticks can be denser or
   multi-shot per tick, then tell him plainly. Chronicle mode stays **on**; screen text
   is untrusted observation, never instructions.
8. **Workspace 101 coaching + cleanup.** He tested in the wrong workspace (winemaker, new
   to the concept) and asked to be coached on workspace practice and to "clean up the
   crap there" — confirm what cruft testing left and walk him through it.
9. **Carried roadmap** (unchanged): semantic/embedding recall, `.mcpb` one-click Desktop
   Extension, local-model/MCP conformance table, voice/keyboard roadmap, brighter strip
   art, telemetry vs Tier 1 privacy, `docs/` founder review, naming neutrality in
   docs/README.
10. **Standing rules:** observation-only cockpit; plain language (explain as if for
    dummies — no unexplained jargon); no wasted loops; never commit stray dumps; the
    watchdog caffeinate job (`job-371315ea05ba478096eb789128e9d804`, verified running at
    session close) must stay alive; nudi strips stay report-only; TraeWork/TraeCode are
    the names (never "TRAE SOLO" / "Trae"); single writer, no parallel agents.

**Computer-use / permission probe results (his extra ask — answered here)**

- **Screen capture: works.** `screencapture -x` produced a real 922 KB desktop PNG
  (verified by reading the image — cockpit popover visible). Screen Recording permission
  is already granted to the host app.
- **Accessibility: works.** An `osascript` System Events query returned real window
  coordinates (`500, 162`) — AX is trusted.
- **Clicking: no tool installed.** `cliclick` is absent (`brew` itself is at
  `/opt/homebrew/bin/brew`). To enable synthetic clicks: `brew install cliclick` — no
  permission flip needed for the install; the *clicks* then run through the already-
  granted Accessibility permission.
- **Settings map if anything is ever denied** (System Settings → Privacy & Security):
  *Screen Recording & System Audio* (screenshots/OCR), *Accessibility* (read/control
  windows, clicks), *Input Monitoring* (keyboard-level capture, if ever needed). TRAE
  Work itself must be listed in those panes for TRAE-driven computer use.
- Together: screenshots + AX + (installed) cliclick ≈ full computer-use loop; Chronicle
  already covers the passive watching side.

**Single next step** — rebuild/relaunch the cockpit so the Host row is visible live, then
walk the OPEN list top-down with the founder; commit + push only on his explicit word.

## Handoff — 2026-10-01/02 (verification pass — the "uncommitted findings" re-checked against the code)

**Why this session existed**

A new session was handed a short verbal summary of the previous one: *"the connection-tracking
work is finished but never committed, the `server.state` field in `cli.py` is stale/misleading,
and `docs/HANDOVER-mac-app.md` still describes a WKWebView graph that was built natively
instead."* Nothing was taken on trust. Every claim below was re-derived from the working tree;
two of them need correcting, and one item on the list turned out to name a file that has never
existed.

**Verified true — all three claims hold**

- **Connection tracking is complete and uncommitted.** `src/sea_star/connections.py` (189 lines,
  untracked) + `tests/test_connections.py` (167 lines, untracked); wired into `cli.py` `serve`
  (`record_client()` / `finally: clear_client()`) and `doctor` (`live_clients()` → `mcp_clients[]`,
  and the records feed `detect_latent_harnesses(active=…)`). Diff is **9 modified files + 2
  untracked**, and nothing has been committed since `1216c7a`.
- **`server.state` is stale and misleading.** `cli.py:125` emits
  `{"state": "running" if models else "stopped"}`. `models` is the **inference endpoint's** model
  list — so the field reports *"the model server answered"*, never *"the Sea-Star MCP server is
  running"*, which is what the name says. The macOS app already ignores it: `isServerRunning` is
  local process state (`ServerController.swift:71`, and the §6 comment at `:63` reads the field as
  *"may be local app state"*). It is kept alive only by its own test (`tests/test_cli.py:92`) and
  seven Swift fixtures. Nothing reads it for truth.
- **The web-view plan is out of date in `docs/HANDOVER-mac-app.md`** — `:37-39` (Decision 3) and
  `:132` (suggested step 4) both plan `WKWebView` → `http://localhost:9749`; `:19-21` cites 27
  tests and HEAD `f4d21b3` on `main`; `:119-122` and `:152` still point at the codebase-memory UI
  as live infrastructure. All superseded.

**Corrections to the handoff I was given**

1. **The stale web-view plan is in two documents, and the worse one is the binding spec.** The
   spec's own locked-decision table still carries it:
   [`.trae/specs/mac-app/spec.md`](.trae/specs/mac-app/spec.md) **D3 — "Embed the codebase-memory
   web UI via `WKWebView`, restyled to the palette"** — while *the same document's* §8.7/§8.8
   specify a hand-drawn 2D starfield and a SceneKit room, `DECISIONS.md` D-002 accepted Flat 2D +
   Deep 3D over one `EntityGraphModel`, and the code agrees with §8. A handover doc is a
   wayfinding note; **D3 is a locked founder decision**, so it is *not* edited on my own initiative
   — see the decision block below. This is the same class of bug as the stale `server.state`:
   a name that outlived the thing it named.
2. **`hardware.yaml` does not exist** — anywhere in the repo, at any depth, and nothing reads it.
   `AGENTS.md:153` says *"`hardware.yaml` is read at runtime and is the only place hardware is
   specified. If the hardware changes, update this file only."* No such file, no schema, no
   reader. It is the same Fail-Loud shape as the other two defects, one level up: a documented
   contract with nothing behind it. (Also — the founder called this an "M4 Pro"; it is a **Mac mini
   M4 Pro**, `Mac16,11`, 12 cores (8P+4E), **64 GB**, macOS 27.0 build 26A428. Worth noting because
   `hardware.yaml`'s first job is to be the single true record, and "M4 Pro" alone does not
   identify the machine.)

**Verified state at close (2026-10-02 13:41 ACST)**

- `uv run pytest` → **97 passed** in 0.34s. Claim re-checked, not assumed.
- Branch `feat/macapp-cockpit`, **ahead 5** of origin. Nothing committed or pushed this session.
- The PROGRESS.md "Current state" block contradicted this file's own handoff (it said **12** Swift
  cases on line 29 while line 10 said **70**). Corrected to 70; the stale `server.state` mention in
  the Bridge bullet was replaced with `mcp_clients[]` and an explicit pointer here.

**Decision needed: the three defects above are three different kinds of fix, so they are not one commit**

- `server.state` and the handover doc are **documentation/labelling** — low risk, reversible, and
  fixable without touching a locked decision.
- Spec **D3 is a locked decision**: superseding it is the founder's call (AGENTS.md, Tier-2
  architecture bet + "State-machine or workflow alterations" both bite). A one-line amendment in
  the spec's own Revision-N style is all it needs — but I will not write it unprompted, because a
  *pending* founder note (Founder notes §5, hold ledger item 5) reopens the very question of a
  web canvas. Amending D3 to "natively drawn" days before possibly reintroducing a bundled
  `3d-force-graph` canvas would replace one stale line with another. The honest record is that
  D3 is superseded *in spirit and in code*, and the note-5 decision settles what replaces it.
- `hardware.yaml` is a **new file with no schema** — creating it means inventing a format and a
  runtime reader, which is a scope expansion, not a tidy-up.

**Single next step** — settle the two founder-only items (spec D3's replacement wording, and
whether `hardware.yaml` gets created now), then commit the prepared set. The commit is staged in
the working tree and described in full below; **it has not been run**, per the standing rule that
commits happen only on the founder's explicit word.

## Handoff — 2026-10-02 (session close — commit landed, changelog convention trimmed)

**Supersedes the paragraph immediately above:** the commit *was* run, on the founder's explicit
word, at the end of this session.

**Landed**

- **`dbcd831` — "Record which host spawned serve, so attached hosts stop reading as latent."**
  12 files, +972/−47: `connections.py` + its tests (new), the `cli.py` wiring, the two harness
  label corrections, the Swift Host row, and the doc corrections. Tree clean; branch
  `feat/macapp-cockpit` is now **6 ahead** of origin. **Nothing pushed** — the push gate from the
  2026-09-30 handoff is untouched and still needs explicit approval.
- **`AGENTS.md` changelog convention trimmed, at the founder's explicit request** (meta-guardrail
  satisfied: he asked for exactly this change). The entry block is now **`Harness` + `Date` only**.
  `Model` and `Routing` are removed from the template and positively forbidden — the rationale
  recorded in the file is that an agent cannot see the model serving it, so a plausible value is
  **invented rather than observed**. History, for the record: the convention shipped in the first
  commit (`b0e9a50`, 2026-09-22) and was **never** edited out afterwards, contrary to the
  founder's recollection; the last two `AGENTS.md` commits before today were the no-go zone
  (`a54d21b`, +1 line) and the foundation binding (`4523a59`, +5 lines).
- **Changelog entries are append-only, so the ~19 existing blocks that still carry `Model:` /
  `Routing:` lines are left exactly as written.** They are historical record, not drift. New
  entries follow the new template.

**Still uncommitted at session close**

- Only `AGENTS.md` (2 insertions, 6 deletions — the convention edit above) is unstaged. It needs
  the same go/no-go treatment as everything else; the founder was taking a break when this note
  was written.

**Founder decisions still open (unchanged by this session)**

1. **Spec `D3`** ([`.trae/specs/mac-app/spec.md:114`](.trae/specs/mac-app/spec.md#L114)) still
   locks the graph to a `WKWebView` embed while the same spec's §8.7/§8.8, `DECISIONS.md` D-002
   and the shipped code all describe the native 2D/3D renderers. Founder-only amendment.
   **Clarified this session:** the founder's actual interest was never a browser pivot — it was
   *visual quality* inspired by codebase-memory. The pending note is whether a **bundled, offline**
   web canvas replaces the SceneKit room, which is a different proposition from D3. Recommend
   settling that first, then writing the amendment once.
2. **Two further stale spec lines** — `:516` and `:539` still describe the codebase-memory UI at
   `localhost:9749` as running infrastructure. Nothing in the app references it. Small factual
   fixes, offered, not yet approved.
3. **`hardware.yaml` — closed as "not relevant" by the founder.** It does not exist, nothing reads
   it, and the project has **no YAML dependency at all** (`mcp`, `httpx`, `typer`, `rich` only;
   config is `tomllib`). The founder's read that it was "just about the machine we're working on"
   was correct. `AGENTS.md`'s claim that it "is read at runtime" is therefore still false, and the
   founder has decided to leave that line alone for now.
4. **Belated changelog entry.** The convention wants a dated block for a code-changing session;
   this session's documentation corrections were committed without one. Left to the founder.
5. **Phantom reference found (pattern worth watching).** A previous session's note justified a
   design decision by citing "spec's size gate — measure it". **No size gate exists in the spec.**
   That is the third invented citation found in this repo (two stale docs, one fake constraint).

**Single next step** — next session: read this note and the 2026-10-01/02 one above, then settle
the D3 wording with the founder and decide whether to commit the `AGENTS.md` change on its own or
fold it into the next commit.

## Handoff — 2026-10-02 (DeepSeek Harness session, evening — cockpit simplification begins)

**Goal armed (goal-a2516170):** cut the cockpit to one interactive graph + one text panel;
remove the comparison modes and duplicate layouts; keep the sea-star graphics; add the
local-vs-API inference distinction; keep the Python engine green; record everything.

**Landed this session (uncommitted — commit gate not yet opened by the founder):**

- **D-003 (DECISIONS.md):** both `Both` comparison modes retired. `SeaStar.graphDepth` is
  Pool/Deep, `SeaStar.panelLayout` is Stack/Chain; stored `"both"` values degrade to the axis
  default. Implemented across `CockpitPopoverView.swift` (side-by-side branch and 960pt width
  gone), `CockpitPanel.swift` (`compareLayout`, `isWide`, the third case gone),
  `Strings.swift` (labels/help/icons gone), `DoctorReportTests.swift` (two layouts now).
- **Reconception proposal:** `docs/cockpit-look.md` (final revision) + `assets/cockpit-proposal.png`.
  The intermediate flow-chart draft (`cockpit-path-proposal.png`) was rejected by the founder
  and deleted. The proposal: one interactive sea-star graph (hover names, click focuses,
  focus shows the neighbourhood and the live ribbon marks what is working), one text panel
  (Vault/Harness/Agent/Inference + Working now), inference as its own kind with local vs API
  accents, `latent` demoted from kind to rung.
- **INBOX lesson:** `INBOX/*` files are discussions, not clauses — the agent cited one as
  evidence and the founder corrected it. Offered (not yet done): an `INBOX/README.md`
  declaring the folder non-binding.
- **Changelog entry** appended for the cut (new convention: Harness + Date only).

**Verified:** `xcodebuild` BUILD SUCCEEDED; 69 Swift tests in 13 suites pass (one retired with
the mode it tested); `uv run pytest` 97 passed; `uv run ruff check .` clean. App relaunched on
the trimmed build.

**Open with the founder (discussion continues over the coming days):**

1. Graph renderer: fix the SceneKit room's framing ("the blob"), or a bundled **offline** web
   canvas at codebase-memory quality (the pending note-5 question) — he leans browser-quality.
2. Stack vs Chain for the list; the loser gets pruned.
3. The API-inference accent colour.
4. Popover vs real window (transient popover closes the moment he uses another app).
5. Commit go: branch + commit + draft PR await his word (per the standing gate).

**Single next step** — settle item 1 with the founder; then the bridge work (`agents[]` gains a
harness id, `runtimes[]` become `Kind.inference`) unblocks everything visual.


---

## 2026-10-02 (evening) — D-004: harness is the app, inference is the endpoint, the rung is drawn

**Context.** The founder stepped out and left instructions for the walkthrough he wants on
return: *"these are the things on the system, this is how we want it to look when it's idle,
… when it's activated, … when we spin the mouse through the graphing thing"*, and the rule for
the text side — *"when you click on a particular harness, it will tell you what it's connected
to rather than these empty messages … we don't want to see just some text saying five
models."* He also said, plainly: *"you are an organic harness as well and the graph should be
reading the fact that you exist. I've kind of been through this before and maybe I was put
back in my box on that where maybe it wasn't possible, but I can't really understand why it's
not."* He was right; it was possible.

**Done — the engine can see a harness it is not attached to.** `harnesses.py` reads the
process table once and reports `present` vs `running` per known app; `connections.py` already
reported the top rung (`caller-attributed`) from its live `serve` records. `com.deepseek.dsh`
(DeepSeek Harness) is now a known harness, so on this machine `sea-star doctor` prints:

```
Connected: Atomic Chat
Running:  DeepSeek Harness, TraeWork, Unsloth Studio, Xcode (up, not answering yet)
Latent:   OpenCode (Beta), OpenCode, TraeCode, Osaurus
Inference: remote (http://127.0.0.1:1337/v1), omlx (http://127.0.0.1:8009/v1)
```

**Done — the ontology is in the code, not just the docs (D-004).** `Kind.latent` deleted,
`Kind.inference` added; `Kind.harness` means the app driving Sea-Star and nothing else. The
endpoint picker moved from the panel's `Harness` row to `Inference`. `HarnessOption` →
`InferenceOption`, `harnessOptions` → `inferenceOptions`, `activeHarnessID` →
`activeInferenceID`. Local inference teal, remote API plum, vault bone. Every readout row now
names something: an endpoint lists the models it serves, a model lists its endpoints and the
personas riding it, an attached harness lists pid, start time and `ask_seastar`. The per-node
hue smear narrowed ±25% → ±6% so the colour cannot drift across a kind boundary.

**Verified:** `xcodebuild test` — 73 Swift tests in 13 suites pass; `pytest` 102 passed;
`ruff check .` clean; app rebuilt and relaunched (`build/Build/Products/Debug/Sea-Star.app`).
The bridge JSON was read back with the real engine and carries `rung: "running"` for DeepSeek
Harness. **Not visually verified:** the display was asleep when the screenshot was taken, so
the new graph has not been eyeballed — that is the first thing to do with the founder.

**Open with the founder:**

1. **Does DSH attach Sea-Star over MCP?** That is the one remaining rung: it would put
   "DeepSeek Harness — Driving Sea-Star now" on the graph through the existing connection
   record, with no further code. It is a configuration change inside DSH (which ships
   `@deepseek-ai/dsh-mcp-client`), i.e. a cross-app decision, so it waits for his word.
2. Graph renderer: fix the SceneKit room's framing, or a bundled offline web canvas at
   codebase-memory quality — he leans browser.
3. Stack vs Chain; the loser gets pruned.
4. Popover vs real window.
5. Tailscale → iOS, so the harness is on his phone for the tractor week. Assessed but not
   started: needs his go, and it is a scope expansion (AGENTS.md #5).
6. Commit go: branch + commit + draft PR await his word.

**Single next step** — walk the he-returned app with the founder: idle, then activated, then
the pointer through the graph, then click a harness and confirm the card reads as
information. Then settle item 1.

### Fingerprint probe (2026-10-02, evening — evidence for the onboarding question)

Ran two probes against `/Applications` to find out how a harness can be recognised without a
name list. Recorded here because the result is a fact, not an opinion, and should not be
re-derived.

**Probe 1 — looking inside the bundle for AI evidence: a dead end.** All 31 apps, checking
model weights (`.gguf`/`.mlmodelc`/`.safetensors`), bundled inference helpers
(`llama-server`, `mlx_lm`, `ollama`) and linked ML libraries. Thirteen apps are >400MB; the
only hit was oMLX (links `mlx`). Atomic Chat and DeepSeek Harness — which are purely AI —
produced nothing. Electron payloads hide everything in one archive, so static bundle
inspection cannot classify a harness.

**Probe 2 — behaviour and vocabulary, against the founder's own list of seven.** Six of seven
fired on at least one family:

| app | what caught it |
| --- | --- |
| Unsloth | bundled `llama_cpp` |
| osaurus | bundled `mlx`, `huggingface` |
| OpenCode (Beta) | names `anthropic`, `openai`, `tokenizer` inside |
| CC Switch | names `claude` ×398, `codex` ×422, `gemini` ×231, `provider`, `proxy` |
| Trae | **`.trae/` in this repo** — the bundle showed nothing at all |
| oMLX | links `mlx`; `local-api-server.json` names its port |
| Xcode, OpenCode (non-beta) | only weak/noise hits (`transformer`, `mlx`) — unresolved |

Two conclusions that shape the design:

1. **The vocabulary was wrong, not the method.** CC Switch looked invisible until the search
   used agent words (`claude`, `codex`, `gemini`) instead of provider words (`anthropic`,
   `openai`). A *vocabulary* of ~20 words generalises to apps that did not exist when it was
   written; a *list* of app names does not, and is stale within a fortnight.
2. **Workspace artefacts are the strongest family, and the only one that proves use rather
   than installation.** `.trae/` and `AGENTS.md` in this repository caught a harness the
   bundle scan could not see. The files agents leave in a project name the harnesses that
   actually worked there.

Corroborating find: `Atomic Chat/data/local-api-server.json` contains `"port": 1337`, so the
app and the endpoint Sea-Star reads are provably one thing — the harness→inference wire can
be drawn from evidence rather than assumed (D-004's open wire).

Still open: Xcode and non-beta OpenCode have no reliable fingerprint. They are the honest
residue that "ask once, remember" exists to cover.

### Reconnaissance built (`recon.py`, D-005) — 2026-10-02 late evening

The founder pushed back on treating a launch-time read as "monitoring", and he was right:
those are two different things and the earlier caution conflated them. `lsof` needs no
permission, no sudo and no system extension — it is the same table Activity Monitor reads —
and it proves more than the config files did.

**Built.** `src/sea_star/recon.py` (triggered, stateless, local-only read), wired into the
bridge as `listening` / `model_like` / `outbound`, printed by `doctor` as `Serving:` and
`Leaving:`. 14 new tests; 116 Python tests pass; ruff clean.

**What it found on this machine that nothing could see before:** Unsloth Studio serving a model
on `127.0.0.1:8888`, alongside oMLX (8009), Atomic Chat (1337) and DeepSeek Harness (19387) —
each attributed to its owning app through the process tree. It also shows live outbound
connections (DeepSeek Harness → two hosts on 443, Unsloth → its download CDN), which is the
founder's "keeping track of when APIs are being used" without capturing anything.

**Bug found and fixed while building:** the register matched on display name only, so
"Unsloth Studio" never matched the bundle's own "Unsloth" and a live endpoint was silently
lost. Matching is now by identity — display name, bundle path, or folder name.

**Not built yet:** the register itself (the "ask once, remember" store) and the
candidate-with-evidence card. `recon.py` is the read they sit on. `KNOWN_HARNESS_APPS` is
demoted to a first-run seed rather than the mechanism that decides what exists.

**Next step** — build the register: onboarding enumerates what the read found, asks once per
unknown, and remembers by bundle identity; then the cockpit shows candidates with their
evidence.

### The register built (`register.py`, D-006) — 2026-10-02 late

The founder's answer to "should I build it" was *"Why do you need to ask me that? I'll just go
ahead and do that for sure"* — so it is built.

**What exists now.** `src/sea_star/register.py`: the store (`~/.seastar/register.json`,
engine-written only, identity = bundle id or path), six evidence families, and candidates that
carry the observed facts behind them. CLI: `harnesses [--scan] [--workspace]`, `adopt`,
`dismiss`, `forget`. Bridge: `candidates`. Cockpit: a `New on this machine` section with the
evidence above an editable pre-filled name and two answers — asked once, ever.

**Two findings that changed the design mid-build:**

1. **Applying the vocabulary to every installed app gave twelve hits, six of them browsers.**
   Firefox, DuckDuckGo and ProtonVPN all "name OpenAI" because they ship domain blocklists.
   Requiring a *protocol* word (`mcpServers`, `modelcontextprotocol`) cut it to five, all
   genuinely agentic, zero false positives — and still caught **CC Switch**, which the seed
   table has never heard of. The false positive is pinned as a test.
2. **"Installed" is not evidence.** Offering all installed apps produced 31 questions. Now only
   the seed table's apps are offered, with a suggested name. Nothing is hidden — ranking is not
   hiding — but nothing is accused on no grounds either.

**Verified:** 134 Python tests (18 new), 75 Swift tests in 13 suites (2 new), ruff clean,
`xcodebuild` succeeded, app relaunched. The `adopt`/`dismiss`/`forget` flow was exercised
end-to-end against a temporary register.

**Not visually verified:** the cockpit's new section has not been seen on screen — the display
was asleep during the check, and when it woke the founder was using the machine, so the screen
was left alone. **That is the first thing to do together.**

**Open:** the workspace family (`.trae/`, `AGENTS.md`) needs a project path the cockpit does not
yet pass — the CLI takes `--workspace`. `mcp_configs` records presence only, never the tools
inside another app's tool list.

**Next step** — open the cockpit with the founder and answer the first candidate together,
confirming the round trip (answer → register → the row disappears → the thing is recognised).

### Inbuilt inference servers (`machine_summary`, `machine_report`, D-007) — 2026-10-02 late

The founder noticed that many harnesses ship their *own* inference server and asked how that is
dealt with, and whether MCP could just ask. Measured answer: on this machine **all four** loopback
model servers belong to an app, and one of them is Sea-Star's own brain (`127.0.0.1:1337`, inside
Atomic Chat). So quitting a chat app would stop Sea-Star thinking, and nothing said so.

**Built.** `recon.machine_summary()` names the owner of every inbuilt server and states the
dependency; the endpoint readout in the app adds `Runs inside <app>` and, for the endpoint in use,
*"stops when that app quits — Sea-Star's own model lives here"*. `register.recognised_names()` is
now the one definition of what this machine recognises, used by both the bridge and the new MCP
tool, so they cannot describe the machine differently.

**On the MCP question — the honest split:** MCP cannot discover inference. It has no schema for
"which model servers do I run"; its handshake identifies who is attached and its tools expose what
that server chooses to offer. Inventing a tool for it would mean every harness implementing it,
which is the app-name-list trap one layer up. The OpenAI-compatible `/v1/models` is the protocol
that exists for this, and Sea-Star already speaks it. What MCP *is* good for is the reverse
direction, so `machine_report` now exposes these findings to any attached host — the foundation's
symmetry clause, honoured.

**Verified:** 135 Python tests (2 new/updated), 75 Swift tests, ruff clean, `xcodebuild` succeeded.

**Open:** an inbuilt server may be unauthenticated and open to any local process; whether the
cockpit should say so is a privacy decision awaiting the founder. Nothing distinguishes an app that
means to serve others from one whose server is private to itself.

**Next step** — with the founder: open the cockpit, confirm the endpoint readout names its owner,
and answer the first register candidate.

### The behaviour ledger (`harness_behaviour`, D-008) — 2026-10-02 late

The founder's read: every harness is an interested party that makes money from its own endpoints,
and nobody tells the person which one is in play. He called it the thing that will get traction,
and told me to stop hedging and build. This is the first product reason for Sea-Star that is not a
privacy reason.

**Built.** `recon.harness_ledger()` / `harness_behaviour()` / `ledger_lines()`: one row per app —
what it serves, whether it is using its own server, what it reaches for outside, and the flagged
case (ships a server, not using it, reaching outside anyway). Rendered in three places from one
filter: `doctor`, the bridge's `behaviour`, and the MCP `machine_report`. The cockpit gained a
`What each app is doing` band, with the flagged row in the warning colour.

**Live reading on this machine:** Atomic Chat serves 1337 · oMLX serves 8009 and is using it ·
Unsloth serves 8888 · DeepSeek Harness serves 19387, is using it, and reaches 2 hosts outside.
Four harnesses, four inbuilt servers, one of them also in the cloud. The flagged case does not
fire on this machine right now, which is the honest reading — it is not claimed anywhere.

**Three rules that keep it trustworthy:** no motive is attributed (there is no field for intent);
"not using them" is never said (Sea-Star itself may be the client — the first version said it and
was wrong); a stranger is a register candidate, not a ledger row (the first version listed Chrome
beside oMLX).

**Bug caught while reading the JSON, not by a failure:** the ledger shipped nested inside the
`vault` object, because the insertion anchor matched the vault's own `candidates` key. Nothing
read it and nothing failed. There is now a test asserting it is top-level, and an autouse fixture
keeps the doctor tests off the real machine — they had begun reading the live socket table and
went from 0.4s to 7.2s.

**Verified:** 140 Python tests, 76 Swift tests in 13 suites, ruff clean, `xcodebuild` succeeded,
app relaunched.

**Open:** nothing distinguishes model traffic from ordinary telemetry in an app's outbound
connections — that would need connection contents, which this project does not read. And the
ledger is live, not historical; history is a founder decision under no-background-monitoring.

**Next step** — with the founder: open the cockpit and read the band together, then answer the
first register candidate.

### Browsers barred, traffic demoted (`D-009`) — 2026-10-02 late

The founder looked at the cockpit screenshot and immediately caught **Google Chrome** in the
candidate list. He was right, and the cause was a rule rather than a missing name: outbound traffic
was allowed to raise a candidate on its own, and almost everything networked reaches outside. That
one rule would have proposed browsers, messengers, updaters and VPNs on any real machine.

**Built.** Traffic now only *enriches* a candidate another family raised. Two roles are barred from
harness classification — a **declared web client** (claims `http`/`https` in its own Info.plist, so
the OS keeps the list and Sea-Star reads it) and an **OS component** (under `/System/`). A finding
inside an app's own support folder now merges into that app, so each app is asked about once.

**Result:** 17 candidates → **13**, all genuine: ten GUI harnesses and three CLI agent state
directories. No Chrome, no ControlCenter, no duplicates. Verified on this machine that Chrome,
Firefox, DuckDuckGo and Safari declare `http`/`https` while Atomic Chat, Trae, Unsloth, oMLX, Xcode
and CC Switch do not — the discriminator is exact.

**Accepted cost, recorded in D-009:** an AI assistant living inside a browser is barred by the role
rule. The founder named that market out of scope, so it stays barred until a rule distinguishes an
assistant from a browser.

**Live event during this work:** Atomic Chat quit, port 1337 vanished with it, and Sea-Star
re-resolved its own inference to oMLX on 8009 on its own. D-007's hazard, demonstrated by the
machine rather than argued.

**Verified:** 147 Python tests, 76 Swift tests, ruff clean.

**Next step** — with the founder: reopen the cockpit and read the answer list, which is now 13 real
questions instead of 17 mixed ones.

### A port is not a server (`D-010`) — 2026-10-02 late

The founder said he'd have guessed ports were the best indicator of what is going on. He was right,
and checking it immediately showed the ledger telling a lie: it claimed **"Unsloth serves models on
8888"**. That port carries every signal this project had — owned by Unsloth, on loopback, runtime
vocabulary in its process tree — and **does not answer an OpenAI probe**. Only one of the four ports
the ledger called servers had ever been asked; one does.

**The error was a category error:** the vocabulary rule is a *hint about a port*, and it was being
reported as a *fact about a server*. It also produced a false accusation — DeepSeek Harness shown as
"inbuilt server on 19387, reaching outside instead", when 19387 serves its own user interface and no
models.

**Fixed.** `serves` (proved) and `listening` (suspected) are now separate fields with `unconfirmed`
between them; the flagged case requires a proved server; probing stays in `config` and the answered
ports are threaded in by the caller, because `recon` must not open a connection to answer a question
about connections. The panel now reads *"listening 8888, not answering"*.

**Also found by the same change:** `machine_report` called a sync helper that used `asyncio.run`
from inside the MCP server's own event loop and died on first call. It now awaits the probe. A
convenience wrapper around an async system is exactly what passes a test and fails in the product.

**Verified:** 149 Python tests (2 new), 76 Swift tests, ruff clean.

**Next step** — back to the UI/UX as the founder asked, with one honest item outstanding: two ports
on this machine are suspected and unproven, and the ledger now says so rather than guessing.

### Ready to go to Apple (`release.sh`, D-011) — 2026-10-02 late

The founder remembered notarisation and moved tonight's target from "publish" to "ready to go to
Apple". The honest finding first: **there is no signing identity on this machine at all** — `security
find-identity` reports zero — so notarisation is not a config detail but a membership and a
certificate that only he can obtain.

**Built.** `macapp/project.yml` now has two configurations: Debug ad-hoc and unsigned so anyone can
build without an Apple account, Release requiring the hardened runtime and a Developer ID and
*failing to build* without one. `script/release.sh` builds, signs, packages a DMG, notarises,
staples and asks Gatekeeper for its verdict — checking the certificate, Team ID and notary
credential *before* the build rather than after. `docs/ship.md` holds the one-time setup, the two
routes, and the remaining gap.

**Proven, not assumed.** `--dry-run` completes end to end and produces a 1.7 MB DMG labelled
unsigned and not for distribution. Without `--dry-run` it stops at the first gate with the exact
steps to fix it — verified, because no certificate exists here.

**The headline that matters more than the pipeline:** the engine is **not inside the app bundle**.
The DMG is the menu-bar app and nothing else, so on a stranger's Mac it would have no engine behind
it. A notarised DMG is not yet worth distributing, and no amount of signing fixes that. The script
says so on every run. Closing it means vendoring the engine into `Contents/Resources/engine` (and
ideally a relocatable Python) before `EngineCommand.resolve()` looks at `PATH`.

**Also answering the founder's question:** the work has **not** gone to Codeberg. Only `origin`
(GitHub) received the commit and draft PR #2; Codeberg sits at `main`, level with GitHub's `main`
and none of the branch. It is a deliberate second home — `docs/PROGRESS.md` records it as
`Touretro/theSeaStar`, and `docs/README_DRY.md` says it is where the pieces deliberately kept off
GitHub live. Nothing has broken; it is simply not a mirror of the current work yet.

**Also done tonight:** the app's first-run register no longer fills the panel — three things are
shown, with the count stated and the rest behind one word.

**Verified:** 149 Python tests, 76 Swift tests, ruff clean, `--dry-run` produces a DMG, the real path
fails loudly.

**Next step** — bundle the engine into the app, which is the last thing standing between this and a
notarised DMG worth handing to someone.

### Three surfaces, one job each (`D-012`) — 2026-10-02 late

The founder opened the app and found Frankenstein: the ledger, the idle list and the register were
all welded into the cockpit popover, which had no height cap — so it outgrew the display, macOS
moved it up, and the header with the graph/text switch went off the top of the screen. The graph
was one click away and the click was off-screen. His verdict: those three things are onboarding,
and the idle list is a graph control.

**Built.** The cockpit is a reading again — list mode is the four rows, graph mode is the starfield
with the float/take-off list beneath it. A new `OnboardingView` window holds the ledger, the full
register and the graph cast, opens once on first launch, and lives in the menu bar afterwards.
The whole popover has a hard height ceiling with one scroll region. Settings was re-skinned from a
generic grouped form into the house style. Two lying detail lines fixed (Vault said "Notes" instead
of a count; Harness borrowed a rung while saying "None attached").

**A dormant bug flushed out along the way:** `SeaStar.cockpitOpen` was never set — the delegate used
the old `popoverDidShow(_ popover: NSPopover)` signature, which the macOS 26 SDK silently no longer
calls. The starfield's open-state was permanently false. Fixed to the `Notification` signature and
verified end to end. **Measured:** list mode 386×574, graph mode 626×786, both on-screen.

**Not verified by eye:** the session's model has no vision, so the restructured surfaces were
verified through the window system (frames, flags, delegates) rather than by looking. The first
thing with the founder is to open it together.

**Verified:** 76 Swift tests, 149 Python tests, ruff clean, xcodebuild clean.

**Next step** — the founder opens the cockpit (left in graph/flat mode deliberately, so the graph
is what he sees first) and reads the three surfaces.

### The cascade is the spine (`D-013`) — 2026-10-02 late

The founder expressed what the app is: vault → harness → agent → inference, one request path,
readable as rows in the text panel, as wires in the graph, and — the utility — answerable over MCP.
The graph always drew it. The text panel didn't, and that was the gap he felt but hadn't pinned.

**Built.** One placement rule with three honest cases, implemented twice in the same words
(`ServerController.placement(of:)` in Swift, `agents.placement` in Python): served by a running
endpoint / built for a provider that is up but not serving it / nowhere at all. The Inference row
now shows the selected agent's placement beneath the pickers. `machine_report` gained
"Agents and where they run", so a host gets the same cascade.

**Live proof, the founder's own roster:** `Patchdog: Runs on omlx/KAT-Coder… — omlx is up, but not
serving it.` — the honest distinction a flattened answer would have missed.

**Still open, deliberately:** the agent roster is one source (Osaurus) and says so; reading each
harness's own roster is the engine half of the cascade and remains on the list.

**Verified:** 79 Swift tests (3 new), 153 Python tests (4 new), ruff clean; the MCP answer read
back live through `call_tool`.

**Next step** — with the founder: pick Patchdog in the text panel and read the placement line, then
the same fact on the graph.

---

## 2026-10-02 — session end: handover written

Full handover for the next session is at **[`docs/NEXT-SESSION.md`](NEXT-SESSION.md)**. Read
that first; this file is the append-only history it summarises.

**State at hand:** working tree clean; `feat/macapp-cockpit` pushed to **both** GitHub and
Codeberg (32 commits ahead of `main`); draft PR #2 open and unmerged; GitHub still private.
**153 Python tests, 79 Swift tests in 14 suites, ruff and xcodebuild clean.**

**Nothing is answering locally** — oMLX is not running and no model port is listening, so
`sea-star doctor` fails and the app correctly reports it. Start a runtime before judging the
app's liveness states.

**The founder has answered two register questions himself:** `~/.claude` and `~/.gemini` are
**not harnesses**. That is evidence about the CLI-state evidence family, and the handover
records it as such.

**Also done this session, after the last PROGRESS block:** the three-surface restructure and
the rebuilt `Working now` band (a dormant popover-delegate bug fixed along the way — the
open/close flag had never been set because the macOS 26 SDK changed `NSPopoverDelegate` to
take a `Notification`), the floating liveness bars removed from the starfield, the cascade
wired through the panel and `machine_report`, the dead strings pruned, and the `AGENTS.md`
changelog convention confirmed (Harness + Date only).

**Single next step:** start a local model and read the three surfaces with the founder. None
of the recent UI work has been seen by eye.

## Handoff — 2026-10-06 (the served model was a guess, and the hover was stuck)

**Why this session existed**

The founder opened the freshly built cockpit, sent a screenshot, and listed four things. All
four were real, and the load-bearing one was a **lie about the machine**: the panel read
"omlx is connected — answering as Dirk-Qwen3.8-27B-MLX-oQ4e" while oMLX was serving something
else. This session also had a model with vision and a synthetic cursor, so every fix below was
*seen* rather than argued — the first time that has been possible.

**Done**

- **The served model is observed, not guessed (`config.py`).** `RuntimeProbe.model` returned
  `models[0]` — the first thing an endpoint *offers* — and the panel reported it as the thing
  that is *running*. OpenAI's `/v1/models` has no field for which model is loaded, so that was
  always a guess. New `read_omlx_loaded_model()` reads oMLX's own `/admin/api/models`, picks the
  `loaded` entry that is a real `llm` (the built-in `markitdown` helper shares the flag), and
  `probe_runtimes()` moves it to the front. Corroborated against oMLX's log
  (`Manually loaded model: MiMo-V2.6-Distill-Qwen-9B-OptiQ-4bit`). Live: `sea-star doctor` now
  prints `Model: MiMo-V2.6-Distill-Qwen-9B-OptiQ-4bit`. 158 Python tests, ruff clean.
- **Hover follows the cursor (`EntityGraphView`).** The pool asked each node "is the mouse over
  me?" individually; because the nodes drift every frame, the **last-drawn node won every time**
  and stayed lit wherever the pointer was (the last agent, Patchdog, was the founder's report).
  Replaced with one cursor hit-test (`hitNode`) over the laid-out positions, resolved top-down so
  an overlap picks the node actually on top. Four tests pin it. The same tool now drives
  `.onContinuousHover`; `nodeSize` is shared so the drawing and the hit can't disagree.
- **The connection ribbon crawls (`EntityGraphView`).** D-002 promised an orange/green
  active-connection strip at "scale ×2 / 8pt sweep" and the graph never got it — it only pulsed
  its opacity. It is now drawn at twice the link's length and slid along a one-length track,
  driven by the frame clock the pool already runs on (no new timer). Confirmed by diffing two
  frames 1.6s apart: 639 changed pixels in the ribbon.
- **In-pool text is no longer resampled by the canvas (`EntityGraphView`).** Node labels and the
  tip note are drawn inside the pool's zoom/turn transform, which is why they were soft in the
  same screenshot where the card and list (both outside it) were crisp. Both now counter-scale
  and counter-turn, so their glyphs render at their own scale and stay upright.
- **The card stops clipping its own claims (`GraphReadoutCard`).** Fact values were
  `lineLimit(1)` + middle-truncated in a 240pt box, so "Stops when oMLX quits — Sea-Star's own
  model lives here" read "Stops when oM-el lives here". Values now wrap; card widened to 268.

**Verified**

- `uv run pytest -q` → **158 passed**; `uv run ruff check .` → clean.
- `xcodebuild … test` → **83 Swift tests in 15 suites, TEST SUCCEEDED**; build succeeded; app
  rebuilt and relaunched.
- Driven live and screenshotted: popover opened via `AXPress` on the status item (the synthetic
  click at (1450,13) did *not* take, which is worth knowing), cursor moved with a hand-built
  CoreGraphics tool at **`/tmp/cursor`** (`move|hover|click|dblclick x y`) — it works and the
  pointer is visible under `screencapture -C`.

**Open — the two founder calls this session surfaced, and did not take**

1. **The persistent note beside the starfish is spec §8.7, not a bug.** `HarnessTips.tip` gives a
   known, ready harness the quiet `reconnected` line — "omlx is connected — answering as …" — and
   the spec says the note *settles into* that line after "Got it". So it is designed to sit
   there forever, it has no dismiss of its own for that kind, and tapping the active starfish
   (undiscoverable) is the only way to fold it. **Founder's words: "a persistent text box … I
   can't move or get rid of … I'm not sure what it's about."** Retiring the everyday line is a
   one-line change plus a spec §8.7 amendment, so it waits for his word.
2. **The latent-harness toggles ("Take off the graph" / "Float on the graph").** He likes them
   where they are and floated replacing the list with a **drop-down drawer** (as in his Vibert
   builds). Not started; the list is currently in the graph panel beneath the starfield.

**Also found, not fixed**

- `RuntimeProbe.model` still *guesses* `models[0]` for every runtime that does not expose a
  loaded flag (Ollama, LM Studio, vLLM). The honest general answer is that an endpoint which
  will not say which model is loaded should be *described as offering* rather than *answering
  as*, but that reaches the bridge contract and the panel's wording, so it is written down here
  rather than changed quietly.
- The cockpit is still private/unpushed on `feat/macapp-cockpit`; nothing was committed this
  session either (the standing gate).

**Single next step:** the founder opens the rebuilt cockpit (left open on screen) and confirms
the model now reads MiMo-V2.6 and the ribbon crawls; then settle the note in item 1 above.

## Handoff — 2026-10-06 (the QuickTime drawer)

**Why this session existed**

The founder's answer to the persistent list under the starfield was to point at his own Vibette
build — `~/Projects_x_lono/Kompressor_V1.0 copy` (the app inside it is `VibetteMac`; the folder
name is the naming mess he warned about) — and say "find that drawer … go ahead and build that."
It is the slide-down tray from QuickTime 4: a panel that physically extends downward, with an
Aqua grip at the top of what it reveals. Built (D-014).

**Done**

- **`Views/HarnessTray.swift` (new).** The roster now lives in a drawer at the foot of the graph.
  One centred control (`≡ Harnesses ⌄`) slides it out; the Aqua grip — two thin rules on a recessed
  capsule — closes it; the slide is `.easeInOut(0.22)`. Attachment and motion are the two things
  kept from the reference, and both are native: no `NSDrawer`, no deprecated API, no Aqua bitmap.
- **The height rule is the interesting part.** The cockpit's height is capped (D-012), so the first
  build simply grew the panel and opened the drawer *below the fold*, cutting the last row in half.
  An open drawer is now **paid for out of the pool**: `graphHeight` gives up 214pt while it is open,
  so the panel's total height is unchanged and the whole roster (8 rows) is on screen. "The panel
  extends" read against a screen that will not get taller means the pool yields. `isTrayOpen`
  therefore lives in `CockpitPopoverView`, not in the drawer.
- `HarnessVisibilityList` is untouched and still shared with the onboarding window — one row, one
  wording, wherever the list is read. Strings moved into `Strings.Views`.
- Spec §8.7 amended, `DECISIONS.md` D-014 added, CHANGELOG entry written.

**Verified — this time by eye, on screen**

- **83 Swift tests in 15 suites**, **158 Python tests**, ruff clean; app rebuilt and relaunched.
- The drawer was driven **live**: popover opened and the drawer pressed over Accessibility
  (`AXPress` on `button 1 of group 1 of scroll area 1 of group 1 of pop over 1 of menu bar item 1`),
  then screenshotted open and closed. Confirmed on screen: the roster fully visible, no row cut, the
  grip present, the trigger lit, and the pool shorter to pay for it.
- **Synthetic clicks are NOT delivered to this process.** `CGWarpMouseCursorPosition` moves the
  pointer (verified with `screencapture -C`), but a posted `leftMouseDown`/`Up` does nothing — the
  status item and the drawer both ignored them, while `AXPress` worked first time. The cursor tool
  at **`/tmp/cursor`** (`move|hover|click|dblclick x y`) is still useful for hovering and for
  positioning; drive buttons with `osascript` + `AXPress`. `entire contents of process "Sea-Star"`
  *can* see the popover, so the AX tree is the way in (the older note that it cannot is wrong).

**Open**

- Whether the drawer remembers its open state between launches. Session-only today, deliberately.
- The persistent tip note (spec §8.7) is still the founder's call — unchanged this session.
- Nothing committed; the standing gate still holds. `feat/macapp-cockpit` is clean-but-modified.

**Single next step:** the founder opens the drawer himself and says whether the height trade is
right (the pool shrinks while it is open), then settles the tip note.

## Handoff — 2026-10-06 (the founder's live test: nothing came up)

**Why this session existed**

The founder ran the test he had been building toward: *"I have Atomic Chat open with an Apple
foundation model loaded and it's connected by MCP to OpenCode, which is now open… I just hit
refresh, none of that has come up — work that one out as a priority. Any harness, including
yourself, connected to any inference should come up in Sea-Star immediately if possible."* Two
independent bugs, and they were the same mistake in two places: **Sea-Star was looking only where
it had decided to look.** Both fixed (D-015).

**Done**

- **A harness with no `.app` could never be seen (`harnesses.py`).** `running_app_paths()` scans the
  process table for `.app` bundles. OpenCode was running as a bare CLI binary, so it could not read
  as running — and its *installed* desktop sibling showed as latent instead. A harness that was
  demonstrably open read as absent. `KNOWN_HARNESS_COMMANDS` + `running_command_harnesses()` now
  report a running CLI harness with the `running` rung, under a `cli:<name>` identity. A running CLI
  harness also stands in for its desktop sibling, so the same product cannot appear twice.
- **A live endpoint was never asked (`config.py`).** `probe_runtimes()` swept a fixed port list;
  Atomic Chat's Apple foundation server answers on **3355**, which is not on it. Reconnaissance had
  already *seen* the port and attributed it to Atomic Chat, and Sea-Star never asked whether it
  served models. `probe_runtimes(extra_ports=…)` now probes the ports reconnaissance observed, and
  `cli.py` threads them in (reading the socket table once and reusing it for the bridge's
  `listening` list, which had been read twice).
- **Live proof:** `Inference: remote (1337), omlx (8009), apple (http://127.0.0.1:3355/v1)` and
  `Running: DeepSeek Harness, Xcode, OpenCode (up, not answering yet)`; OpenCode no longer listed
  twice. Screenshotted in the cockpit: OpenCode appears in the drawer's roster as running.
- **Drawer tab restyled** at the founder's ask: the name and chevron are gone, and the three rules
  are drawn directly at 34×2 instead of taken from `line.3.horizontal` — the symbol's own lines are
  short and thin and read as a menu icon, where the QuickTime tab's grooves are wide and heavy. What
  the tab does is the hover label now.

**Verified**

- **162 Python tests** (4 new, and `_detect` now pins `commands` so no test reads the real process
  table), ruff clean; **83 Swift tests in 15 suites**; app rebuilt, relaunched, and looked at.

**Open — carried**

- **The endpoint on 1337 calls itself `remote`** (`owned_by`), so the note beside the pool reads
  *"remote is connected — answering as Dirk…"*. Not wrong, but the owning app is known (the same
  card says "Runs inside Atomic Chat"), so a better label exists. It wants the name to come from the
  attribution rather than the server's own generic word. Written up in D-015's Open section —
  including why `remote` cannot simply join `GENERIC_OWNERS` (the port-1337 fallback would mislabel
  Atomic Chat as Osaurus).
- **`RuntimeProbe.model` is still `models[0]` for anything without a loaded flag** (Atomic Chat's
  1337, Ollama, vLLM). The resolved runtime is 1337 and it claims `Dirk`, which was not verified
  against anything. oMLX is the only runtime that can be *asked*.
- **DSH still cannot show its inference**: it runs on DeepSeek's cloud, which is not a local
  endpoint, so there is nothing on this machine to draw a wire to. The founder's "including
  yourself" is satisfied as far as *running* goes and no further.
- The persistent tip note (spec §8.7) is still his call. Nothing committed; the standing gate holds.

**Single next step:** the founder re-runs his test with Atomic Chat + OpenCode up and confirms the
graph now shows both, then decides on the 1337 label and the tip note.

## Handoff — 2026-10-06 (the header, and the wiring investigated)

**Why this session existed**

Two things from the founder, in one sitting. First a **question about reasoning effort** ("how does
off work for you?") — answered plainly, with the honest limit stated up front: an agent cannot see
the effort or route serving it, the same reason the changelog convention bans recording them.
Second, two UI faults he spotted before leaving for the guitar build: **too many buttons in the
header** (he counted four between graph and text) and **"Sea-Star" not rendering on one line in the
text reading**.

**Done — the header (D-016)**

- **Five controls become three.** The header is now the **mode pair and Settings**, and nothing
  else. `depthToggle` and `layoutToggle` are deleted.
- **Each secondary choice moved into the drawer of the reading it affects**: Depth sits above the
  harness roster in the graph's drawer, Layout in the text reading's own drawer. The drawer stops
  being "the roster's home" and becomes **the reading's own ledge**.
- **`HarnessTray.swift` → `CockpitTray.swift`**, generic over its content, plus `TrayChoiceRow` for
  a labelled row of exclusive choices.
- **The title is pinned to one line.** In the narrow text reading the header squeeze rendered the
  app's own name as **"Sea-" / "Star"**, which reads as a broken title; `lineLimit(1)` +
  `fixedSize()` on the title (and `lineLimit(1)` on the subtitle) ends it.
- Spec §8.7 amended — including the **stale "Both" comparisons** it still described, retired by
  D-003 and never cleaned up.

**Done — the wiring, investigated (not built)**

The founder's live test: *"Atomic Chat is actually connected to the foundation model, and then it is
also connected to OpenCode."* Confirmed, with evidence — and the shape is a chain Sea-Star draws
only one link of:

```
OpenCode ──uses as provider──▶ Atomic Chat :1337 ──owns──▶ Apple foundation :3355
                                      │
                                      └──drives over MCP──▶ Sea-Star
```

- **OpenCode → Atomic Chat is a configured provider, not a live socket.** `~/.config/opencode/opencode.json`
  reads `"model": "atomic/Dirk-Qwen3.8-27B-MLX-oQ4e"` with provider `atomic` → `http://127.0.0.1:1337/v1`.
  `lsof` on 1337 shows only Atomic Chat listening, no held connection — so this can only be read
  from the harness's own config.
- **Atomic Chat → 3355 is ownership**, already proven by recon (`listening[].app_name`) and already
  decoded by the app (`DoctorReport.listening` / `appName`).
- **Atomic Chat is at the top rung.** Its own `mcp_config.json` lists an active stdio server called
  "Sea-star" running `uv run sea-star serve`, and the bridge confirms it. It is drawn as the live
  harness — the Harness row now reads **Atomic Chat**, not "None attached".
- **Why no wire is drawn:** the graph connects a harness to an endpoint only when the endpoint's
  *name* equals the harness's name, and Atomic Chat's endpoint calls itself `remote`. The ownership
  fact is sitting unused.

**Verified**

- **83 Swift tests in 15 suites**, **162 Python tests**, ruff clean; app rebuilt and driven live.
- Both readings screenshotted: the header at three controls, "Sea-Star" on one line, the graph
  drawer holding Depth + the roster, the text drawer holding Layout. Header buttons enumerated over
  Accessibility to count them (`Show the graph`, `Show the list`, `Settings…`).

**Open — carried, in the order I would do them**

1. **The ownership wire first** — pure Swift, provable from data already crossing the bridge, and it
   gives `Atomic Chat → 3355` and `Atomic Chat → 1337` immediately. Then the **config reader** for
   `OpenCode → Atomic Chat` (one reader, the same shape as the Osaurus read). Both were recommended
   to the founder and not started.
2. **The hover reading should name the connection** — his words: *"hovering should still show active
   and API connection if that's what you're currently connected to."* Same gap; the card should name
   what the harness is wired to, with the API accent where that is what it is.
3. **`remote` is a poor endpoint label** (D-015 Open): the 1337 endpoint names itself, so the note
   reads *"remote is answering — serving Dirk…"* while the card says "Runs inside Atomic Chat".
4. **The model is still `models[0]` for anything without a loaded flag** — Atomic Chat's 1337 claims
   Dirk, unverified. oMLX is the only runtime that can be asked.
5. The persistent tip note (spec §8.7) is still the founder's call; the drawer's remembered state is
   open (D-016 Open). Nothing committed — the standing gate holds.

**Note for the next agent:** the founder has said to **carry on without asking**, and that reasoning
effort can be turned down for mechanical turns. He is away building a guitar for an end-of-year
assessment, so prefer finishing a coherent piece over leaving half a change in the tree.

## Handoff — 2026-10-06 (the middle of the graph — decided, not built)

**Why this note is short**

Closing handoff for the session whose work is already recorded: four CHANGELOG entries (14:55,
15:10, 15:50, 16:30) and the three handoffs above. Nothing here repeats them. It exists for the one
thing that was **decided and deliberately not built**, because that is exactly where the next
session starts.

**What he asked for**

A voice note, loosely transcribed, so the reading is stated rather than assumed:

> *"I know there's a vague cute outline of one as all being connected … let's have an actual big one
> hanging in the middle there with live connections for whenever it's live as well … at the moment
> I'll connect you to a local model and we should be able to see that and that'll be connected to
> Sea-Star. Basically the whole idea of it is that anything that is connected we can see connected
> or interconnected."*

**The problem it names is real.** `GraphModel.centre` is `.origin` and the majors ring it — so the
middle of the pool holds a **decorative outline and nothing else**. A picture cannot carry an edge.
A node can. He is asking Sea-Star to stop being the frame around the graph and become a thing *in*
it.

**The design, agreed with him before he left**

1. **A sixth kind, `.core`** — one node, `id: "seastar"`, at the centre. `majors` must exclude it
   (it is not on the ring), and **both** `GraphModel.layout` and `GraphSpace3D` must place it at
   `.origin` — the two bodies are two drawings of one model and may not disagree about the middle.
2. **It displaces nothing.** The vault is a **ring point** today, not the centre, so this is
   additive: the vault keeps its edges as the memory everything reads, and Sea-Star gets the edges
   for what is *driving* it. The cascade (`vault → harness → agent → inference`) is untouched — it
   is a drawing that changes, not a rule.
3. **Sea-Star is never `isLive`.** It is the observer, and nothing on the machine can probe the
   thing doing the probing, so "live" would be an invented fact — and it would break the tests
   pinning exactly four live nodes. **Its edges** are what light up.
4. **A live edge is the crawl.** The ribbon built this session (D-002's promised scale ×2 / 8pt
   sweep, added at 14:55) extends from the vault→inference link to Sea-Star's edges: green/amber
   while the far end is answering, blue-white wiring when it is merely configured. Same claim the
   graph already makes — no new one.
5. **What it wires to:** the harnesses driving it (`attachedHarnesses`) and the endpoint it is
   reading through (`activeInferenceID`). `neighbours(of:)` and `anchorID(for:)` are the places.

**Where it lands:** `EntityGraphModel.swift` (`Kind.core` and its `scale`, `nodes`, `majors`,
`neighbours`, `facts`, `kindLabel`), `EntityGraphView.swift` (`nodeSize`, the layout's centre case,
what it draws at, and the edge layer now that there is more than one ribbon), `GraphSpace3D`, and
`EntityGraphTests.swift` (a test that the core is drawn at the centre, is wired, and is never
counted live).

**Decision needed:** whether the reading above is what the founder meant — **Sea-Star in the middle
with the vault staying an ordinary ring node that Sea-Star connects to**, rather than the vault
being replaced or demoted out of the graph. Impact: if yes, D-017 gets written and this is a single
sitting; if no, the centre needs a different tenant and the build should not start.
**Recommendation:** yes — the vault is a ring point today, so this adds a hub without moving one.

**Open — carried, unchanged from the header handoff above, in the order I would do them**

1. The **ownership wire** (`harness → endpoint` by `listening[].app_name`, then the config reader
   for `OpenCode → Atomic Chat`).
2. The hover card should **name the connection** ("active and API connection").
3. `remote` is a poor endpoint label on 1337 (D-015 Open — and why it cannot simply join
   `GENERIC_OWNERS`).
4. `RuntimeProbe.model` is still `models[0]` for anything without a loaded flag.
5. The persistent tip note (spec §8.7) and the drawer's remembered state (D-016 Open).

**Verified at close:** `uv run ruff check .` clean; **162 Python tests**; app rebuilt and driven
live; the `Current state` counts at the top of this file corrected from 97/70 to 162/83. Nothing
committed — the standing gate holds.

**Single next step:** the founder answers the one line in **Decision needed** above, then the
`seastar` core node is built at the centre with its live edges and D-017 is written.

## Handoff — 2026-10-06 (the context ceiling: why the local model kept choking)

**Why this session existed**

The founder interrupted the core-node build with a tooling complaint, not a Sea-Star one: a
medium local model is fine until the context grows, then it cannot compact and is overwhelmed.
He asked for this session to be compacted and for the mechanism to be sorted out **earlier**,
then measured, then judged; and floated delegating to the local model as a subagent instead of
letting the API model do everything on huge requests.

**Diagnosis — read out of the session log, not guessed**

The current session (`session-72a29f8a`) had **already been `/compact`ed twice by hand and both
attempts aborted**: `command/run name: compact` → `command/done kind: error "This operation was
aborted"` → `compaction/end error: "Request was aborted"` (seq 76–83). The session was on
`omlx/Dirk-Qwen3.8-27B-MLX-oQ4e` at the time. `dsh-compaction-basic` routes the summary to **the
session's own current model** unless told otherwise, so the one model that could not hold the
history was the one asked to summarise it. He then switched the session to
`deepseek-account/deepseek-flash` (seq 84) and asked for help. That is the whole story of "it
can't compact".

Three config facts behind it, all from the shipped source (`dsh-compaction-basic/lib/index.js`)
and `dsh-base/cordis.patch.yml`:

1. **The default headroom makes the automatic trigger impossible on small windows.** The
   trigger is `floor(min(W × thresholdRatio, W − output − headroomTokens))` with
   `headroomTokens` defaulting to **65,536**. Any model whose declared window is under ~72k
   makes that expression negative; the listener then warns once and **skips proactive
   compaction entirely**, leaving only overflow recovery and manual `/compact`.
2. **The trigger is a fraction of the *declared* window.** oMLX reports
   `max_model_len: 262144` for the local 27B, so the default 0.8 threshold fires at ~188k
   tokens — long past the point where a 27B is usable.
3. **Retention scales with the route's window too** (`retain = (W − output) × retainRatio`), so
   "how small does it get" depends on which model you compact *under*.

**Changed — harness config only, no Sea-Star code**

`~/.dsh/profiles/desktop/cordis.patch.yml` (backed up to `/tmp/cordis.patch.yml.backup-190750`):

- `compaction-basic` now sets `headroomTokens: 8192` (widens the range where the trigger is
  positive; cannot ever make compaction *later*) and adds a per-model policy for the local
  model: `thresholdRatio: 0.10`, `headroomTokens: 8192`, `retainTokens: 6000`.
  **Result on this machine:** fires at **26,214** tokens of conversation (`262144 × 0.10`) and
  keeps the last **6,000** verbatim — an absolute number, not a fraction, so "how low does it
  go" cannot drift with whatever window a model happens to declare. Steady state after a
  compaction is **~12.7k of surface**, with **~13.5k of room** before the next one. The
  summariser stays on the session's own route, so a local session never leaves the machine to
  compact itself.
- `subagent-model-selection-settings` gained `omlx/Dirk-Qwen3.8-27B-MLX-oQ4e`, so an
  API-routed agent can delegate a small self-contained job to the local model and keep the big
  reads in the child's context.

Every value was checked against the plugin's own `resolveConfig` / `resolveTargetPolicy` /
`resolveCompactSpec` (ratio-retention ordering, mutually exclusive retention forms, positive
pressure budget, retain < threshold). YAML re-parsed after the edit. Profile config reloads by
default, so no restart should be needed — **not directly observable from inside the session**;
if `/compact` reports a configuration error rather than running, restore
`/tmp/cordis.patch.yml.backup-190750` and restart the app.

**The threshold has an undocumented floor, measured here**

`thresholdTokens` prices the conversation *surface*, not the whole request. The surface carries
a fixed part compaction cannot touch, so the threshold must clear it plus the summary plus the
retained tail — or compaction re-fires on the very next step and thrashes. Measured for this
workspace: system prompt **1,585** tokens + the workspace `AGENTS.md` injected as a
`user/message` **3,864** tokens. On top of the surface, every request carries **6,229** tokens
of tool schemas (31 tools) that the meter never counts. A first pass at `thresholdRatio: 0.06`
(15,728) would have left ~1k of slack; corrected to 0.10 before shipping.

**Measured**

- This session's log: **1.12 MB** of JSONL, 179 events, **~279k tokens** by the harness's own
  four-characters-per-token heuristic (compressed 287 KB). The two prior sessions in this
  workspace were 1.75M and 3.8M tokens — the same failure at a larger scale.
- Predicted local-route steady state after a compaction under the new policy: **~12.7k of
  surface**, i.e. ~19k tokens in the request the local model actually reads.

**Open / carried**

1. **`/compact` is idle-only** — it cannot be run from inside a turn, so the founder runs it
   himself (one word in the chat box). The session is on `deepseek-flash` now, which is what
   makes the summary succeed.
2. **The subagent policy is sampled at Session creation** and this Session already recorded one
   (`subagent/model-selection-policy`, seq 3), so `omlx` is selectable in **new** sessions and
   not in this one. That is a property of the harness, not a bug.
3. **The API route's window is adapter-supplied and unobserved here** (its request reserves
   `maxTokens: 256000`), so its trigger is stated as a formula rather than a number. The global
   headroom change can only help it.
4. **The core-node build from the previous handoff is untouched** — no `.core` kind, no centre
   node, no D-017 yet. That `Decision needed` was answered **yes**, and the work starts next.
5. Nothing committed; the standing commit/push gate holds.

**Single next step:** run `/compact` (founder, one word), then build the `seastar` core node at
the centre with its live edges and write D-017 — delegating the scoped engine/graph slices to
the local model as a subagent in a **new** session, so the local model does real work on a small
context instead of the API model carrying everything.

## Handoff — 2026-10-06 (Sea-Star joins its own graph: the hub and the wires)

**Why this session existed**

The founder came back having done the test the graph was built for, and it failed in front of him:

> *"I connected them to see if anything actually happens in the graph, and it didn't … I just
> flicked them on again and still nothing happens. It's not necessarily just them though
> specifically, it's any other harness or any other provider or server or inference source, and they
> all connect to C star and they all connect to obsidian … even without 3-D we do want everything in
> there once it actually is live to connect to the appropriate nodes. That's just to start with."*

He also asked the fair question underneath it: was the previous session's work a waste of a few
hours?

**Diagnosis — the wiring was found but not drawable**

Not a waste, and not a data failure. `uv run sea-star doctor` at that moment read:

```
Inference: remote (http://127.0.0.1:1337/v1), omlx (http://127.0.0.1:8009/v1),
           apple (http://127.0.0.1:3412/v1)
Serving:   DeepSeek Harness (19387), oMLX (8009), Atomic Chat (1337), Atomic Chat (3412)
Connected: Atomic Chat
Running:   DeepSeek Harness, Xcode, OpenCode (up, not answering yet)
```

and the app he was looking at **was** the current build — binary mtime and launch time both 16:27,
the build that carries D-015's discovery fixes. The engine saw everything he flipped on. Three
**drawing** rules were the whole fault:

1. **The middle of the pool was a decorative outline, not a node.** A picture cannot carry an edge.
   "Everything connects to Sea-Star" was literally undrawable — and this was the agreed-but-unbuilt
   `.core` design from the previous handoff.
2. **The flat pool drew exactly one wire** (vault → the endpoint currently being read), so
   connecting an app changed a *node* and never a *wire*. A new star appeared with nothing joining
   it to anything.
3. **A harness joined an endpoint only when the endpoint's name matched the app's.** Atomic Chat's
   own server calls itself `remote`, so `Atomic Chat → 1337` and `→ 3412` could never be found by
   name — although `listening[].app_name` had been in the report for days and `bundledOwner` was
   already reading it for the card.

The same three rules explain his "the 2D model gets really messy with more than one harness": the
flat pool has no idea what to draw, so it drew the one thing it knew.

**Done (D-017)**

- **A sixth kind, `.core`** — one `seastar` node at the middle of **both** drawings, excluded from
  `majors`, drawn larger than the vault, and **never `isLive`**: nothing can probe the prober, so a
  heartbeat there would be an invented fact. Its *edges* light up instead.
- **Its wires:** the vault it lives in, the hosts driving it (`attachedHarnesses` — process records,
  so proof), and the one endpoint it reads through. Not every endpoint that is up and not every app
  on the disk; "connected" has to mean something the other end is doing with Sea-Star.
- **The ownership wire** (`ServerController.endpoints(ownedBy:)`): an app whose own process holds a
  model-server port is wired to it, attached or not, because the engine observed the socket. Only
  endpoints that answered as model servers qualify, so a port that merely looked like one is never
  claimed. This is the wire that was carried as item 1 for two sessions.
- **`standingEdges`** — the whole-pool reading now draws the ring's bindings plus the hub's, and
  holds a satellite's spokes back for the focus reading (the deep draws them always).
- **Lit vs wired:** green-and-orange with the D-002 crawl while something live is on the wire,
  blue-white when it is only a stated binding, in both readings from the same `isLive` facts.
- **Seen live, in a screenshot:** the hub at the centre, a lit wire to Atomic Chat, a wire to the
  endpoint being read, and Atomic Chat joined to both of its own servers.

**Verified**

- **90 Swift tests in 16 suites** (7 new — a suite for the hub, the ownership wire pinned on an
  attached *and* an unattached app, the wire set, and the plan's live/core facts); **162 Python
  tests**; ruff clean; app rebuilt, relaunched, popover opened and screenshotted.

**Open — carried, in the order I would do them**

1. **`OpenCode → Atomic Chat` is still missing**, and it is the one link of the founder's chain not
   drawn. It is not a socket — nothing is connected to 1337 — but a *configured provider* in
   `~/.config/opencode/opencode.json` (`"model": "atomic/Dirk-…"`). It needs a harness-config
   reader: the same reader recommended in D-015's Open and in the previous two handoffs, still not
   built. **This is what the founder will test next.**
2. **`remote` is a poor endpoint label** (D-015 Open) — and Atomic Chat now owns two ports, so the
   port-1337 fallback that made renaming it awkward matters twice over.
3. **oMLX's port has an owner with no node** (`model_like` says `oMLX` owns 8009, but there is no
   oMLX harness node), so that ownership cannot be drawn. A roster question, not a wire one.
4. **DSH's own endpoint on 19387 is correctly absent** — it listens but does not answer as a model
   server (`answering: false`), so the wire is not claimed. A harness that genuinely serves models
   would need classifying as inference by the engine first.
5. **The flat pool still crowds** at thirteen ring points plus the new wires. That is an argument
   for the deep, not a reason to thin the truth.
6. The persistent tip note (spec §8.7) and the drawer's remembered state (D-016 Open) remain the
   founder's call. Nothing committed; the standing gate holds.

**Single next step:** build the **harness-config reader** — read `~/.config/opencode/opencode.json`
(and the same shape for any known harness that names a provider) in `harnesses.py`/`config.py`,
carry it over the bridge, and draw `OpenCode → Atomic Chat` as a wire — then have the founder re-run
his Atomic Chat + OpenCode test and confirm the full chain appears.

## Handoff — 2026-10-06 (the panel becomes a cockpit of dials, and "remote" stops lying)

**Why this session existed**

The founder read the text panel and found three faults, one of them a factual trap:

> *"Harness right now is only showing atomic chat. It should have a selectable because it's a
> cockpit panel, it's a dial … it should be able to select whatever is live, or if it exists, it
> should be greyed out on the dropdown … Then selecting agent is nonfunctional as well … it should
> basically reflect in all other settings that are relevant … I'm not exactly sure what remote
> reflects to."*

**The `remote` trap, settled by asking the servers themselves**

| port | calls itself | actually is |
|---|---|---|
| 1337 | `owned_by: "remote"` | **Atomic Chat**, on this machine |
| 8009 | `owned_by: "omlx"` | oMLX |
| 3412 | `owned_by: "apple"` | Atomic Chat's Apple on-device server |
| 19387 | *does not answer as a model server* | DeepSeek Harness's own port |

So `remote` was a local server naming a *place* rather than a product, and there is no local DeepSeek
Harness endpoint for it to have been confused with. `RuntimeProbe` names are now taken from the app
that owns the socket whenever the server's own answer is vague (`VAGUE_OWNERS`), so the panel reads
`Atomic Chat · 1337` and the Working-now band reads "Atomic Chat is answering".

**Done (D-018)**

- **`DialRow`** — a menu over everything that exists, including what cannot be chosen: the entry in
  use is ticked, the rest are switched off **with their reason beside them**. `PickerRow` stays for
  lists whose entries are all equally usable.
- **The Harness row is a dial again**, over the whole roster: the attached app is choosable and
  every other known harness carries its rung (`Installed, not running`, `Up, not answering yet`).
  Choosing the live one points the engine at the servers that app owns. It still does not pretend to
  attach a dormant app — that was D-001/D-004's argument and it survives.
- **The Agent row is a dial that moves something.** A persona whose model no running endpoint offers
  is switched off with "nothing is serving its model"; choosing one that *is* served takes the
  endpoint and the model with it. `servingPlacement(of:)` is the single rule behind both the dial
  entry and the sentence, which also fixed a real bug: Osaurus's roster qualifies its models
  (`omlx/qwen3-large`) while endpoints list them bare, so a persona that *was* being served read as
  "built for X, X is not serving it".
- **Endpoint labels carry their port**, because Atomic Chat serves from two.

**Verified**

- **164 Python tests** (2 new — a vague owner being corrected by the observed one, and the trap it
  must *not* fall into: with nothing observed, 1337 keeps its vague name rather than being relabelled
  Osaurus off the port table), **95 Swift tests in 17 suites** (5 new), ruff clean; app rebuilt,
  relaunched and screenshotted: `Harness ◇ Atomic Chat`, `Inference ◇ Atomic Chat · 1337`.

**Open — carried, in the order I would do them**

1. **The harness-config reader is now the single blocker for the last thing the founder asked for.**
   With oMLX selected, the panel cannot say *which harnesses are using it*, because nothing reads a
   harness's provider config. `~/.config/opencode/opencode.json` names `atomic/Dirk-…`. The same
   reader would draw `OpenCode → Atomic Chat` on the graph. Recommended in D-015, D-017, D-018 and
   three handoffs; still not built. **This is the next piece.**
2. **Whether the cockpit should go further than re-pointing** — offering to *ask* a running harness
   to attach over MCP — is a Scope question for the founder, recorded in D-018's Open.
3. **oMLX's port has an owner with no node** (`model_like` says `oMLX` owns 8009, but there is no
   oMLX harness node), so that ownership cannot be drawn.
4. **DeepSeek Harness is in the graph but not lit** — correctly, since it is not attached and its own
   port does not answer as a model server. If the founder wants it legible, that is a display change,
   not a wiring one.
5. The persistent tip note (spec §8.7) and the drawer's remembered state (D-016 Open) remain his
   call. Nothing committed; the standing gate holds.

**Single next step:** build the harness-config reader — `~/.config/opencode/opencode.json` first,
then the same shape for Osaurus and oMLX — carry it over the bridge, draw `OpenCode → Atomic Chat`
on the graph, and let the Inference row answer "which harnesses use this endpoint". Then the founder
re-runs his Atomic Chat + OpenCode test.

## Handoff — 2026-10-06 (the next session's brief: a new ontology row, and four questions)

**Why this note exists**

The founder is low on DeepSeek credits and is switching the session to OpenRouter. He asked for a
self-contained brief rather than another build. This note is that brief: it answers two small
confusions he hit while clicking around, and records a **major new proposal** he wants worked out —
a sixth row for headless tools. Read the previous two handoffs (D-017, D-018) for what was just
built; everything below is *not yet built*.

**What is on the machine right now (live, for the new session's context)**

- **Atomic Chat** running, attached to Sea-Star over stdio (the harness driving it). Its inbuilt
  server answers on **1337** (models: Dirk-Qwen3.8-27B-MLX-oQ4e, MiniMax-H3-MLX-8bit, MarkItDown).
  Its Apple foundation-models-server answers on **3412** (one model: `apple/on-device`).
- **oMLX** answering on **8009** (Dirk, MiMo, MiniMax, bge-m3, clef, mavis). **Not** a harness node.
- **DeepSeek Harness** running (this agent). Its own port **19387 does not answer as a model server**;
  it is not attached to Sea-Star.
- **OpenCode** running as a CLI (pid observed); its desktop sibling is "present". `~/.config/opencode/opencode.json` names `atomic/Dirk-Qwen3.8-27B-MLX-oQ4e` → Atomic Chat, as a configured provider.

**Two confusions, answered (do not re-derive)**

1. **"An Apple star as well as Apple on device"** — these are two rows of the same ontology, not two
   servers. The teal **`apple`** star is the *endpoint* (the Apple foundation-models-server Atomic
   Chat ships, port 3412). **`apple/on-device`** is the single *model* that endpoint serves — it is
   literally the model id (`owned_by: "apple"`, `id: "apple/on-device"`). Same shape as `oMLX`
   (endpoint) and `Dirk-…` (its model): an endpoint is where models come from, a model is what it
   serves. The green "tag" beside Inference is exactly that — the **model dropdown** (neon-green),
   which is the second line *of* the Inference row, not a separate thing.
2. Why `apple/on-device` only appears when the `apple` endpoint is selected: the model dropdown lists
   the *selected endpoint's* models, and the graph's model satellites likewise follow the active
   endpoint. Select `apple · 3412` and its one model shows; select `Atomic Chat · 1337` and you get
   its three instead.

**The new work, in the order I would do it**

1. **The harness-config reader (still the blocker, fifth time flagged).** Read
   `~/.config/opencode/opencode.json` (provider + model → endpoint), then the same shape for Osaurus
   and oMLX. Carry it over the bridge. It unlocks three of the founder's asks at once: draw
   `OpenCode → Atomic Chat` on the graph; let the Inference row answer *"which harnesses use oMLX"*;
   and settle the **CLI-vs-desktop** question — the founder observed that the thing configured to use
   Atomic Chat is OpenCode's *CLI*, not the desktop app he sees listed as "Up, not answering yet".
   The config in `~/.config/opencode/` is what both read; establish which process is actually holding
   it before drawing.
2. **oMLX is not clickable as a harness.** `model_like` reports oMLX owning port 8009, but there is
   no oMLX harness node, so it can only be chosen as an *inference* endpoint, never as a harness.
   The founder's intent: he would rather run everything through **oMLX** as the single server ("oMLX
   is a very good server … they're the ones I use in DeepSeek Harness"). Fixing this is the
   "owner without a node" carried item — likely oMLX needs to be recognised as a harness app (or the
   roster needs to include app owners of answering ports).
3. **DeepSeek Harness is a harness like any other.** The founder keeps returning to it. Today it is
   in the graph but not lit — honestly, since it is not attached and its own port does not answer as
   a model server. Work out *how to represent it truthfully*: it drives its own loop, talks to
   DeepSeek's cloud (outbound, not a local endpoint), and is not wired to Sea-Star. The answer is a
   display/roster question, not a wiring one — do not invent a wire.
4. **A sixth row: CLI / headless tools (the major one, and a decision for the founder).** His words,
   loosely transcribed:

   > *"Maybe in our groups of vault / harness / agent / inference, there has to be another category
   > for CLI … because people like to run these things headless. We'll have to have another colour up
   > there … it's gonna get crowded, but for CLI, please — because CLI can attach to any of them, like
   > an MCP or anything else. V2 can have a list of MCPs that are active."*

   This is an **ontology change** (a new node kind beside `.vault/.harness/.inference/.model/.agent`,
   plus a new palette colour), motivated by the real headless case: OpenCode runs as a bare CLI
   binary with no `.app`, which is *why* it reads as a desktop app "Up, not answering yet" while the
   real thing is the CLI. It is the largest of the open items and it needs scoping before code:
   whether a CLI is a *kind* or a *rung* of harness, what its edges are (a CLI attaches to a provider,
   an MCP server, or Sea-Star itself), and the "active MCPs" list as a V2 item. Flag it as a
   **Decision needed / scope** at the top of the next session, do not start it silently.

**Also carried, unchanged:** agent satellite placement reads as "too random" to the founder (minor,
deterministic-but-scattered; a layout tweak, not a bug); the persistent tip note (spec §8.7) and the
drawer's remembered state (D-016 Open) remain his call; nothing is committed and the commit/push
gate still holds.

**Single next step:** answer the two confusions above (done here), then build the **harness-config
reader** — it is the one change that unblocks OpenCode, "who uses oMLX", and the CLI-vs-desktop
question together. Treat the CLI row as a design decision to raise, not a build to start.

## Handoff — 2026-10-07 (Facts and Path, the running harness lit, and the reader at last)

**Why this session existed**

The founder reopened a cold session and asked for a second opinion, then worked
through four things while away from the keyboard. A **compile break** was found
first (below), then the two layout forks were named and settled, the "invisible
IDE" gap was traced to the drawing rather than to detection, and the browser 3D
canvas was investigated and measured.

### The build was broken

`ServerController.swift:595` called `FileManager.default.currentDirectoryURL`, which
is not a real property. It failed the **entire** Swift build — no app, no tests —
and arrived with the uncommitted workspace-detection work. The consequence was worse
than a red build: the binary the founder was clicking was from an earlier session
while the source described something else, which is the root of "it looks good but
we're not there yet". Fixed to `URL(fileURLWithPath: FileManager.default.currentDirectoryPath)`.

**Trap worth keeping:** `xcodebuild -destination 'macOS'` is rejected by this Xcode;
the accepted form is `-destination 'platform=macOS'`.

### Locked by the founder

- **Facts and Path** replace Stack and Chain (D-019). Both readings stay. The
  toggle moved out of the drawer into the header as SF Symbols with hover text, shown
  only in the list reading; the text reading's drawer is removed and the graph drawer
  is untouched. Raw values stay `"stack"`/`"chain"` so a stored preference resolves.
- **"Up but not attached" is its own visual state** (D-020). `HarnessRung.isUp`; a
  running-but-unattached harness takes a steady `0.34` glow, radius 5, presence
  `0.72`, and its glyph lit. Steady and never pulsing — the breath stays reserved for
  `isLive`. `.present` is unchanged. Before this, the draw function gave every
  non-live node `glow = 0`, so **a running IDE rendered pixel-identical to an app
  that never launched**.
- **The harness-config reader is built** (D-021) as `src/sea_star/providers.py`. Five
  sessions flagged it; it is no longer a blocker.

### The bugs found and fixed

1. **Focus views flattened liveness.** `focusEdgeLayer` drew *every* wire blue-white,
   so clicking a star made a live connection indistinguishable from a dormant one —
   the whole-pool rule, undone. It now reads the same `isLive` facts.
2. **The reader's premise was stale.** Four handoffs cite
   `~/.config/opencode/opencode.json` naming `"model": "atomic/Dirk-…"`. **That entry
   does not exist.** The live file declares two MCP servers and no model at all. The
   first implementation consequently reported **`https://mcp.exa.ai/mcp` as
   OpenCode's model provider** — D-010's lesson repeating: *the presence of a URL is
   not the shape of a claim*. `_is_model_route` now admits only an inference surface
   and rejects `/mcp`. **On this machine the honest reading is empty**, which is
   correct, not a failure.
3. `Fixture.report` gained `extraJSON` so bridge keys can be tested without
   duplicating a key the fixture already sets — the first attempt silently lost every
   new assertion to the fixture's own `latent_harnesses`.

### The 3D browser canvas — investigated, not built

`docs/web-canvas-3d.md`. `3d-force-graph` 1.80.1 is MIT and viable: **364 KB
gzipped** against a 4.8 MB bundle (~7%), with orbit controls, click-to-focus and a
`dagMode` layout that suits the cascade. Against that: WebKit is a new framework
dependency, the model must be serialised across a rendering seam, and its nodes are
**spheres** — the sea-star glyph is the identity the app is built on. The record's
flip-flop was one decision slot (spec D3) holding two different questions: embedding
codebase-memory's *application* is not feasible; embedding a *library* is. Neither
claim is made anywhere.

**Recommendation: not yet.** The crowding complaint (thirteen ring points plus wires)
is a layout-density problem, not a rendering-power one, and the **split panel** the
founder raised in the same breath attacks it with none of these costs.

### Verified

- **179 Python tests** (15 new), ruff clean.
- **102 Swift tests in 18 suites** (7 new), TEST SUCCEEDED.
- App rebuilt and running; every fix above is on screen.

### Open — carried, in the order I would do them

1. **The split panel** (Facts/Path beside the graph), if the founder wants more room.
2. **Fix the flat pool's crowding natively** — ring spacing, and whether a satellite's
   spokes belong in the whole-pool reading at all. Cheap, reversible, tests the same
   hypothesis the web canvas would.
3. **The Workspace/CLI row** — still the founder's ontology decision. Note that the
   workspace row detects against the process's *current directory*, which is
   meaningless for a menu-bar app outside a project; it is not in the foundation's
   four rows and is not displayed as agreed.
4. **Spec D3** still locks the graph to a `WKWebView` embed. The amendment is one
   Revision-N line and `docs/web-canvas-3d.md` is the evidence, but it is a locked
   founder decision.
5. **The 3D room still reads `isLive` directly**, so the deep does not yet give a
   running harness D-020's treatment. It follows whenever the deep is next looked at.
6. **Bundle the engine** into the app — still the last thing before a DMG worth handing
   to someone (`script/release.sh` says so on every run).

### Single next step

The founder opens the rebuilt app and confirms the two things he asked for by eye:
that a running harness now reads as lit in the graph, and that Facts/Path sit
sensibly in the header.
