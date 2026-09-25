# Changelog

All notable changes to Sea-Star are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
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
