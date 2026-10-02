# Progress

Live build state and session handoff. Read this before starting work; append a handoff
note at the end of every session.

## Current state

- **Version:** 0.1.0 (unreleased). Repo is **private** until built and tested.
- **Health:** `uv run ruff check .` clean; `uv run pytest` — 97 passing. App:
  `xcodebuild … test` — 70 Swift Testing cases passing (13 suites). Both re-run at session
  close 2026-09-30.
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
  It builds, launches, and its 70 Swift Testing cases pass (13 suites). Popover shows vault/harness/model
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
