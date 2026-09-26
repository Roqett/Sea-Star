# Changelog

All notable changes to Sea-Star are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Harness: TRAE

Date: 2026-09-26

Summary of Changes:
- **The menu bar wears the detailed starfish, in both appearances (spec §7).** The glyph was a
  solid star; it now shows the same detailed starfish as the popover header, drawn by the one
  `AppIconMark` so the two can't drift. The four faces collapsed to a **single cut each**
  (`IconRoster`'s `asset`, the former `Face*Header`), rendered as a **template** on every
  surface, so the system tints it white on a dark menu bar and black on a light one and the fine
  line art stays legible either way. The bare cut read as a snowflake, so the mark now draws a
  **solid band partway out from the fuzzy centre** — a sea-star's body, with the ray tips still
  free — which keeps it from reading as either a snowflake's spokes or a cog's rim.
- **Both panels gained light and dark mode; the starfield stays dark (spec §7).** `Palette.swift`
  now splits into an **adaptive chrome** layer (`canvas`, `ink`, `inkMuted`, `logInk`, `logSurface`)
  that resolves per appearance — an `NSColor` dynamic provider keyed on
  `bestMatch(from: [.darkAqua, .aqua])` — and a **fixed-dark `pool`** that keeps the entity graph
  and its ink pinned dark. The graph on a pale canvas looked silly; it does not any more. Verified
  offscreen by sampling both appearances (canvas `#10131A`↔`#F7F3EC`, ink `#EDE3D2`↔`#1C1A17`,
  pool `#10131A` both).
- **The log's nudibranch strips are inset (spec §8.8).** The blue-white ribbons are floated on the
  log ground and pulled in from the edges to match the Start/Refresh controls, so they read as
  wiring *inside* the panel rather than its border; ground and ink adapt with the panel.
- **README polished.** Subtitle typo fixed ("One-click's ease" → "One click's ease"), Local-first
  and MCP badges added (all `?style=flat-square`), a new **At a glance** summary, the page count
  corrected to five, and the founder's closing note centered. Every fact and link unchanged.
- **Tests:** `xcodebuild … test` → **28 tests in 8 suites passing** (run twice across the icon and
  palette changes).

Harness: TRAE

Date: 2026-09-26

Summary of Changes:
- **The cockpit no longer runs off the bottom of the screen (spec §8).** The panel's height was
  only ever whatever its stacks added up to — an unbounded body plus a 150pt logs panel plus the
  header and the controls — so on a shorter display (or with the logs open) the bottom fell off
  the screen and was clipped. The whole cockpit is now capped to the screen's usable height
  (`NSScreen.visibleFrame` less a margin) and the middle section scrolls to fit, so every control
  stays reachable.
- **Operator instructions, in both tracks (spec §10 / T6.x).** New `docs/use-the-app.md`: the
  menu-bar Cockpit on one side (get it, open it, read what it found, choose, go) and the exact
  terminal equivalent on the other, headed by the parity table so no step exists on only one
  side. Linked from `docs/README.md` and the root `README.md`. It also records that macOS builds
  do **not** have to be shell-first (Xcode's own headless `xcrun mcpbridge`, §9.1) and that the
  `.icns` app icon (T4.4) is unnecessary while the app is `LSUIElement` (no Dock presence).
- **A no-go zone for every agent (AGENTS.md).** The founder's external drive — and any mirror of
  it — is off-limits: no reading, indexing, embedding, summarising or transmitting anything from
  it to a cloud or third-party model. Local-only at most, and only on an explicit written ask.

Harness: TRAE

Date: 2026-09-26

Summary of Changes:
- **The mode switch moved into the header (spec §8.7).** The cockpit's Graph/List choice was a text
  capsule sitting in the body; it is now two standard Apple symbols — connected points for the
  graph, a bulleted list for the rows — up with the **"ready"** pill and the gear, the active
  reading lit the way Apple lights a segmented control.
- **First launch asks how to open (spec §8.7).** Before a preference exists the popover shows a
  one-time chooser offering both readings (either will do); the answer is remembered in
  `UserDefaults` (`SeaStar.cockpitMode`) and the header icons swap it from then on. Until a choice
  is made the graph shows behind the question and neither icon is pressed.
- **Tests:** new `CockpitMode` cases (an unset preference opens the graph, a stored preference
  round-trips both ways, every reading carries a symbol, a label and a help line) —
  `xcodebuild … test` → **28 tests in 8 suites passing**.

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **A tip grows from the starfish (spec §8.7).** A short note now opens beside the active node in
  the graph, and tapping that starfish expands or contracts it. The rule is pure and unit-tested
  (`Models/HarnessTips.swift`): a harness the person has **never been on** gets a setting-up hint,
  other vaults nearby raise a **wrong-vault** nudge, and a known, ready harness gets a quiet
  **"connected — *n* models on offer"** line. Seen harnesses are remembered in `UserDefaults`
  (`SeaStar.seenHarnesses`, keyed by endpoint) and a fresh hint is dismissed with **Got it**, after
  which the note settles into the connected line.
- **The starfield moves (spec §8.7).** The entity graph is no longer a still frame. The orbs now
  drift on a slow per-node current (each entity's phase is hashed from its id, so nothing jitters
  between redraws), their glow breathes, and the vault↔harness connection **grows out of the
  vault** — the nudibranch ribbon is masked from the vault end and drawn on whenever the active
  harness changes, so the strip visibly *shoots out* at the thing it just connected to. Each orb
  also picks up the `caustics` Metal highlight used elsewhere. The whole pool stills under
  **Reduce Motion**.
- **The Logs toggle is findable.** The cockpit's Logs control was a bare mauve word nobody could
  spot; it is now a proper disclosure row — a rotating chevron, a terminal mark, the title and a
  live entry count, with a hover fill and a Show/Hide tooltip — so the panel is obvious to open
  and close.
- **Tests:** new `HarnessTips` cases (fresh hint, connected line, wrong-vault nudge, silence when
  not ready, idempotent remembering) — `xcodebuild … test` → **25 tests in 7 suites passing**.

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **Cockpit controls de-capsuled (spec §8).** The glass Start/Refresh pills are gone. Both are
  now plain mono words — small, toned down, the way Apple draws a text button — with **Start in
  the left corner and Refresh in the right**, and a clean band of space above and below the
  pair. A **blue-white nudibranch strip** sits above and below that band as the column
  reference the 3px bar was always meant to be.
- **Nudibranch strips land in the app (spec §7).** The founder's three 3px ribbons are now
  asset-catalog imagesets (`NudiBlueWhite`, `NudiGreenOrange1`, `NudiGreenOrange2`) rendered
  with `template-rendering-intent: original` so their gradients survive, and wrapped by a
  reusable `Views/NudiStrip.swift` (2px default, `expands` toggles full-width rule vs. fixed
  connection stroke).
- **Logs, kept short on purpose (spec §8.8).** A new `Services/LogStore.swift` pipes the
  engine's `stdout`/`stderr` into one durable, selectable log. The cockpit gains a collapsible
  **Logs** panel bordered top and bottom by the blue-white strip, inked in the matching blue
  (`logInkDark` / `logSurfaceDark`; a light pair is defined for an adaptive surface) in **SF
  Mono**. Settings gains a **Logs** section: a retention window (**Forever / 7 / 14 / 30 days**,
  default 14), an entry count, **Clear now**, and **Reveal in Finder**. Pruning runs on every
  write against `~/Library/Logs/Sea-Star/sea-star.log`, so nothing piles up on the disk the way
  most apps let it.
- **Entity graph — the "starfield" view (spec §8.7).** A segmented **Graph | List** toggle
  (List is the default) switches the popover between the familiar rows and a dark backdrop of
  glowing nodes: the vault on the left, harnesses down the right edge, the active harness's
  models ringing it, each in its own accent (`vaultGlow`/`harnessGlow`/`modelGlow`). Hovering or
  selecting a node reveals its name; tapping one drives the same `selectVault` /
  `selectHarness` / `selectModel` calls the list uses. The vault↔harness **connection** is drawn
  as a rotated nudibranch strip.
- **Tests:** new `LogStore` cases (the retention rule as a pure function — old lines dropped, a
  zero window keeps everything, the offered windows, plain-language labels) — `xcodebuild …
  test` → **20 tests in 6 suites passing**; `… build` → **BUILD SUCCEEDED**.

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **Right-click menu on the glyph — the "must have" (spec §8.6).** SwiftUI's
  `MenuBarExtra` renders the popover but exposes **no** right-click hook, so an accessory app
  had nowhere to put the standard app menu. The shell was rebuilt around AppKit: a new
  `@main enum SeaStarMain` starts `NSApplication` directly and hands off to a new
  `App/AppDelegate.swift`, which owns the `NSStatusItem` and shows an `NSMenu` on
  right-click (⌃-click too): **Check for Updates…**, **Settings…** (⌘,), **Help & Comments**,
  **Patchdog**, a disabled **Version × (build)** line, and **Quit Sea-Star** (⌘Q). Left-click
  still opens the cockpit popover. `App/SeaStarApp.swift` (the old `MenuBarExtra` shell) was
  deleted; the popover and settings are the *same* SwiftUI views, hosted in
  `NSPopover` / `NSHostingController`.
- **Settings window (spec §8.4).** A new `Views/SettingsView.swift` — the configuration
  surface the menu opens. Engine resolution + path, a **searchable** scrolling vault list with
  **Open folder… / Use detected vault**, harness/model pickers, an inline update check, and
  links (Help & Comments, Patchdog, repository).
- **GitHub Releases update check (spec §8.5).** New `Services/UpdateChecker.swift` asks the
  Releases API for `Roqett/Sea-Star`'s latest release and compares it to
  `CFBundleShortVersionString` as dotted numbers (a leading `v` and ragged segment counts are
  tolerated). Only a genuinely newer release offers to open its page; a failure says so
  plainly. `Support/Links.swift` is the one home for every external URL; `Support/AppInfo.swift`
  reads the bundled version/build.
- **Vault row can now search and adopt any folder (spec §8.1).** The popover's vault menu
  gained **Open folder…** (a folder picker → `SEASTAR_VAULT`), and its `PickerRow` no longer
  greys out when there is a folder entry to reach. `ServerController.clearVaultOverride()`
  returns to autodetection.
- **Model row follows the selected harness (spec §8.3).** `ServerController.modelOptions` now
  prefers `currentHarness.models` (falling back to `report.models`), so a Qwen model served
  only by oMLX appears the moment oMLX is chosen — the model that "wasn't coming up".
- **Popover scrolls (spec §8).** The header and the start/stop controls stay pinned; the
  detail body scrolls inside a `maxHeight: 320` region, so a long report no longer overflows
  the panel.
- **Tests:** new `Version`/`UpdateChecker.normalize` Swift Testing cases (newer wins; equal or
  older never does; leading `v` + ragged segments; tag normalisation) — `xcodebuild … test` →
  **16 tests in 5 suites passing**; `… build` → **BUILD SUCCEEDED**.
- **Real faces wired in (spec T4.3/T4.4 cuts).** The roster now points at the founder's
  actual artwork: each face ships two asset-catalog imagesets — `Face*Header` (40/80/120px)
  and `Face*MenuBar` (18/36/54px) — all black-ink-on-transparent, `template-rendering-intent:
  template`. The menu bar wears the solid silhouette (fine line art turns to grey mush at
  18pt); the popover header wears the full-detail cut, tinted by the face's accent. Both are
  templates because the ink lives in the alpha channel — that is what keeps the filigree
  readable on the near-black canvas, where the original black-on-clear art would vanish.
- **Header caustic shimmer (spec T4.5).** A new stitchable Metal shader
  (`Shaders/Caustics.metal`, wrapped by `Views/CausticsEffect.swift`) drifts a slow
  value-noise highlight across the header mark only. The highlight is gated by the artwork's
  own alpha, so the silhouette never moves — only the light travelling across it does — and
  the whole effect is disabled under **Reduce Motion**. Header-only: the menu-bar glyph stays
  a flat tinted glyph, where motion would just be noise.
- **`AppIconMark` renders both cuts as templates and sizes raster art explicitly.** Raster
  images ignore `.font`, so a `size` parameter now frames them (`resizable().scaledToFit()`),
  with the SF Symbol fallback kept behind it. `CockpitPopoverView` shares one `markSize`
  constant between the mark and the shimmer so the two can't drift apart.
- **Easter egg: the app has four faces and changes it on open/shut.** All four of the
  founder's icons are held in one roster (`Support/IconRoster.swift`) and the app wears one
  at a time. Every time the server is started or stopped it rerolls to a **different** face —
  never the one that just went away, which is the bit that makes the change read as
  deliberate. The face shows on **both** surfaces: the menu-bar glyph and the popover header
  (each face also carries its own glow colour, so the swap is obvious).
- **`ServerController` now owns `currentIcon`** and advances it on genuine start/stop
  transitions (and on a vault/model switch, which restarts). The controller is hoisted into
  `SeaStarApp` so the `MenuBarExtra` glyph is state-driven rather than a fixed symbol, and the
  popover reads the same instance.
- **Multi-harness detection (fixes the "Refresh missed my model" bug).** The engine's
  `detect_runtime()` probed `KNOWN_RUNTIMES` in order and adopted the **first** that
  answered, so if Osaurus (1337) was up it always won and shadowed oMLX/Ollama/LM Studio —
  the panel showed `osaurus · foundation` instead of the model being loaded elsewhere.
  `config.py` now exposes `probe_runtimes()`, which probes **every** live runtime
  concurrently (one `PROBE_TIMEOUT_SECONDS` budget via `asyncio.gather`) and returns a
  `RuntimeProbe` per live responder. `detect_runtime(probes=…)` and
  `load_config(probes=…)` reuse the survey, so single-runtime machines behave exactly as
  before while multi-harness machines see all of them.
- **Localhost port sweep (harness ports are not fixed).** oMLX's documented default is 8000,
  but the same person often runs a second copy on 8009 and other machines pick other ports —
  probing one address per harness still missed the model actually in use. `probe_runtimes()`
  now sweeps a standard set of localhost ports (`scan_ports()`: known-harness ports first,
  then extras like 8009/5000/9000) and names each responder by its self-reported
  `owned_by` when that is specific (oMLX says `"omlx"`), falling back to the port's known
  harness and then `"local"`. Generic owners (`library`, `user` …) are dropped so they don't
  masquerade as a harness. `SEASTAR_SCAN_PORTS` (comma-separated) replaces the set wholesale
  for an unusual setup. Still local-only and inside the same timeout budget.
- **The bridge now carries `runtimes[]` (spec §6).** `doctor --json` emits one object per
  live harness (`name`, `base_url`, `model`, `models`); the key is optional and
  `schema_version` stays `1` — the engine only ever adds keys, so an older app still decodes.
- **Cockpit: harness pick-list (spec §8).** The Harness row becomes a `PickerRow` when more
  than one harness is live and a plain `StatusRow` otherwise; the current choice is labelled
  `name · url` (an endpoint alone can't say which app answers on a shared port). Switching
  pins `SEASTAR_BASE_URL` + `SEASTAR_RUNTIME` — the same knobs the engine reads — and clears
  any model override, since the old model may not exist on the new endpoint.
- **Build note:** `.metal` files need Xcode's separately-downloadable Metal toolchain; on a
  fresh machine run `xcodebuild -downloadComponent MetalToolchain` before building.
- **Tests:** `IconRoster` (four distinct faces; a reroll never repeats the current face;
  a reroll with nothing showing still returns a face) plus the cockpit's opening face and
  the new `runtimes[]` decode — `xcodebuild … test` → **12 tests in 4 suites passing**;
  `… build` → **BUILD SUCCEEDED**; `Assets.car` (40 KB) and `default.metallib` (69 KB)
  confirmed in the bundle; app launches without crashing. Python: `pytest` → **51 passed**
  (multi-harness + sweep cases: every live server reported, scan order kept, a port-name
  fallback, an unlisted port named `local`, the `SEASTAR_SCAN_PORTS` override, a specific
  `owned_by` kept / a generic one dropped, a survey reused without re-probing, fails loud
  when nothing answers).

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **Cockpit: vault and model pick-lists (spec T3.2/T3.3).** The popover now offers the
  other Obsidian-known vaults (`vault.candidates`) and the endpoint's models (`models`),
  with the current choice shown in-row and checked in the menu. Switching re-runs the
  bridge with `SEASTAR_VAULT` / `SEASTAR_MODEL` pinned — the same knobs `resolve_vault`
  and `load_config` already read — so no engine change was needed. Choosing while the
  server is running restarts it so the new choice takes effect.
- **`EngineCommand.Invocation` now carries environment overrides**, threaded through
  `EngineClient.doctor` and `ServerController` and merged over the inherited environment.
  New Swift tests cover the threading and the empty-choice case (7 tests / 3 suites;
  `xcodebuild build` + `test` green).

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **macOS menu-bar app ("Cockpit") scaffolded** under `macapp/` — a SwiftUI
  `MenuBarExtra` app that wraps the engine with no terminal. XcodeGen project
  (`project.yml`), bundle id `UpPeriscope.Sea-Star`, deployment target macOS 26.0,
  files split `App/ Views/ Models/ Services/ Support/`. Builds, launches, and its four
  Swift Testing cases pass. The menu-bar mark is a placeholder SF Symbol until the
  founder's monochrome template icon lands (spec T4.3).
- **`doctor --json` reshaped to the full §6 bridge contract.** It now emits
  `schema_version` and a nested `vault { path, source, note_count, candidates }` object
  (was a flat `vault` string + `notes`), plus `server.state`. One JSON object, always,
  even on failure; human output stays the default.
- **Vault resolution moved into `config.py`:** `detect_vault_candidates()` (open-first,
  then most-recent) and `resolve_vault()` returning `(path, source)` with `source` ∈
  `env` / `toml` / `obsidian`, failing loud when none resolves — so the app can show
  *why* a vault won and offer the alternatives.
- **`tests/test_cli.py` added** for the JSON bridge (shape, fail-loud single object,
  human default), and `tests/test_config.py` extended with vault candidate/resolution and
  `allows()` coverage (spec T1.5/T1.6/T1.8). Engine: `ruff` clean, **40 tests** passing.
- **`macapp/SeaStar/Services/EngineClient.swift` + `Models/DoctorReport.swift`** — the app
  decodes the bridge object; it never scrapes human-formatted text.

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **`doctor --json` — the app bridge contract.** `sea-star doctor` now takes `--json` and
  always emits one JSON object (vault, notes, runtime, base_url, model, models, bridged
  servers), even on failure, so a host app can poll it instead of scraping rich text. The
  human output is unchanged and still the default.
- **Curated bridged tools with `include` / `exclude`.** Each `[[mcp.servers]]` entry can
  carry `include` (allowlist; empty = every tool) and `exclude` (denylist; always wins).
  Filtering happens at connect time in `mcp_client.list_external_tools`, so the agent only
  ever sees a short, intentional tool menu.
- **README rewritten as two equal tracks.** A terminal-first path (available now) and a
  GUI-first path (coming), with a "Two ways to run it" parity table; dropped the marketing
  pull-quote and the `## The name` section; documented `include` / `exclude`.
- **mac-app spec → Revision 2, and now tracked.** Folded in the two-track
  instruction model (D9), the identity/naming decision (D10), the corrected Xcode toolchain
  (native `xcrun mcpbridge` path, §9.1), and the planned Omarchy (Arch Linux + Hyprland)
  port. The spec set (`spec.md`, `tasks.md`, `checklist.md`) is now committed under
  `.trae/specs/mac-app/` so it is versioned alongside the code; `.trae/*` is gitignored
  except `specs/`.
- **Added `docs/README_DRY.md`** — a spin-free reference doc (IS / DOES / SOLVES /
  DE-COMPLICATES) for cross-checking the Omarchy port with other models.
- **Naming settled: the repo stays at `Roqett/Sea-Star`.** Notarisation and the bundle id
  depend on the Apple Developer account, not on GitHub, so no org is required. All links
  were repointed from `UpPeriscope/Sea-Star` back to `Roqett/Sea-Star`; "Up Periscope"
  remains the product identity (licence + bundle id).

Harness: TRAE

Date: 2026-09-24

Summary of Changes:
- **Pointed every link at the renamed repository.** The GitHub repo is now `Roqett/Sea-Star`; clone URLs, `[project.urls]`, the docs and the changelog footer were updated to match, and the local `origin` remote was repointed.
- **Added oMLX to the runtime lists** (`README.md`, `docs/reference.md`, `docs/start-here.md`, `docs/troubleshooting.md`, `docs/README.md`, `AGENTS.md`) and to `KNOWN_RUNTIMES` in `config.py`, default endpoint `http://localhost:8000/v1`. It shares that port with vLLM; oMLX is probed first so autodetection labels the runtime `omlx`, and it needs no configuration.
- **README:** added a one-line warning to add `seastar.toml` to `.gitignore` when the vault is under version control, since the file can hold a real `api_key`.
- **Hero image:** replaced `assets/seastar_sf.png` with the updated artwork at `assets/sea-star.png` and repointed the README at the new path.

Harness: TRAE

Date: 2026-09-23

Summary of Changes:
- **Renamed the project to Sea-Star.** The display name, docs prose and ASCII art now read `Sea-Star`; the Python import package moved `src/seastar/` → `src/sea_star/`; the CLI command is now `sea-star`. The distribution name stays `seastar-mcp`, and on-disk identifiers stay `seastar.toml`, `.seastar/`, `~/.config/seastar/config.toml` and the `SEASTAR_*` environment variables, so existing setups keep working unchanged.
- **Toned down the README voice.** Plainer, more grounded language throughout; trimmed the wordplay that was getting in the way of the point.

Harness: TRAE

Date: 2026-09-23

Summary of Changes:
- `src/sea_star/mcp_client.py` — fixed `remote.inputSchema` → `remote.input_schema`. Under the pinned `mcp>=2.0` (installed: 2.2.0) the camelCase name no longer exists, so bridging any external MCP server (the "Way 3" capability) raised `AttributeError`. Verified against the installed library and re-run: ruff clean, 27 tests pass.

Harness: TRAE

Date: 2026-09-22 21:51 ACST

Summary of Changes:
- `docs/README.md` — new docs index; routes readers by who they are.
- `docs/start-here.md` — zero-jargon explainer: what Sea-Star is, what you need, the three moves.
- `docs/connect.md` — new connection guide: how to wire Sea-Star into Osaurus, Claude Desktop, Cursor and TRAE, and what to say to the host's agents.
- `docs/reference.md` — technical reference: CLI, MCP tools, config keys, runtimes, env vars, security model, invariants.
- `docs/troubleshooting.md` — failure modes and fixes, grounded in real errors.
- `docs/PROGRESS.md` — live build state and session handoff.
- `README.md` — added a Documentation section linking the docs index; linked Way 2 to the connect guide.
- `.gitignore` — added `INBOX/` so the document-staging folder never ships or commits.

### Added

- **Runtime-agnostic inference** (`inference.py`): talks the OpenAI-compatible
  chat-completions protocol over raw `httpx`, so Ollama, LM Studio, llama.cpp,
  MLX, vLLM and Unsloth Studio all work without a vendor lock-in.
- **Zero-config autodetection** (`config.py`): probes the six common local ports
  and adopts the first runtime that answers; fails loud when none do.
- **Obsidian vault autodetection** (`config.detect_vault`): reads Obsidian's own
  `obsidian.json` (macOS, Linux and Windows locations), prefers the currently-open
  vault, and falls back to the most recently used one — so `sea-star serve` works
  with no configuration at all.
- **Obsidian vault memory** (`vault.py`): scan, ranked search, read, write and
  append, with traversal-safe paths and `[[wikilink]]` citations.
- **Bounded agent loop** (`agent.py`): model turn → tool calls → observations →
  cited answer, capped by `max_steps`.
- **MCP server** (`mcp_server.py`): exposes `ask_seastar`, `vault_search`,
  `vault_read` and `vault_list` over stdio for Claude Desktop, Cursor, Trae, etc.
- **MCP client** (`mcp_client.py`): bridges external MCP servers (e.g. Obsidian
  ones) into Sea-Star's own tool registry under namespaced names.
- **CLI** (`cli.py`): `sea-star init | doctor | ask | serve | version`.
- **Factory protocol** (`AGENTS.md`): Tier 1/Tier 2 tripwires and core invariants.
- Test suite covering the vault, config resolution, tool registry, agent loop and
  MCP server surface.

### Changed

- **README focus** — added the "Osaurus + Unsloth Studio" setup recipe: Osaurus as
  the agent harness, Unsloth Studio as the OpenAI-compatible model server, Sea-Star
  as the shared private memory. The runtime-agnostic contract is unchanged.
- **Brand** — the octopus sign from The Sea Star (2289 3rd Street, Dogpatch, San
  Francisco) is now the repo's front image, with a short note on where the name
  comes from.
- Aligned the README's config file name, vault key and `[[mcp.servers]]` shape with
  the actual implementation.

### Fixed

- Corrected `agent.build_agent` to import `list_external_tools` (it previously
  referenced a non-existent `load_external_tools`, breaking every config that
  declared a bridged MCP server).

[Unreleased]: https://github.com/Roqett/Sea-Star/commits/main
