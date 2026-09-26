# Spec — Sea-Star macOS menu-bar app ("Cockpit")

> Foundation document for the Mac GUI workstream. Authored as the TRAE **Spec** layout
> (`spec.md` + `tasks.md` + `checklist.md`) so it is equivalent to what the `/spec`
> workflow generates, and lives as a version-controlled knowledge asset.
>
> Status: **draft — awaiting founder review.** No GUI code has been written against this spec.
> Two engine-side groundwork items it depends on have landed since the first draft: the
> `doctor --json` bridge (§6) and the scoped tool surface (§5, D8). Both are green.
> **Revision 2** folds in the founder's directive for **two first-class instruction tracks**
> (§10, D9) and **corrects §9**: a native, headless Xcode MCP path exists for macOS, so the
> earlier *"macOS must be shell-first because the plugin is iOS-only"* note was wrong.
> Source of truth for the workstream: [HANDOVER-mac-app.md](file:///Users/lono/Random_MCP/theSeaStar/docs/HANDOVER-mac-app.md).
> Live build state: [PROGRESS.md](file:///Users/lono/Random_MCP/theSeaStar/docs/PROGRESS.md).

## 1. Summary

Build a **lightweight, native macOS menu-bar app** that wraps the existing, finished
Python engine so the founder never has to open a terminal. Click the star, get a compact
popover, see what the engine found (vault, harness, model), click once to start/stop the
server.

- **Product:** Sea-Star — free (MIT), local-first, runtime-agnostic MCP server that turns
  an Obsidian vault into a private AI agent. Public goal: *"one-click, just works."*
- **Why the GUI exists:** the founder is comfortable with Swift basics only and is
  **allergic to the terminal**. That constraint drives the **GUI-first** track — but it is
  a *default*, not a cage: a **terminal-first** track ships alongside it (§10, D9), so
  CLI-comfortable users are served just as well.
- **Engine status:** done and green — `uv run ruff check .` clean, `uv run pytest` →
  27 passing, version `0.1.0` (unreleased). Re-verified at this revision. The two
  groundwork items the GUI leans on are in: `doctor --json` (§6) and per-server
  `include`/`exclude` tool scoping (§5, D8). Neither has dedicated tests yet — see T1.5
  and T1.6.

## 2. Goals

1. Zero-terminal operation for the everyday flows: detect → choose → start → stop.
2. A machine-readable bridge to the engine, so the GUI never scrapes human-formatted text.
3. A genuinely contemporary **Liquid Glass** macOS look, using current Apple tooling.
4. A menu-bar presence that is unmistakably Sea-Star but **monochrome** (see §7).
5. Shippable to the founder first as a local build; notarised later for other people.
6. **Two equally-easy instruction tracks** — GUI-first (zero terminal) and terminal-first
   (CLI parity) — so neither audience is alienated (§10, D9).

## 3. Non-goals (v1)

- No rewrite of the Python engine. Keep the 27 tests green.
- No cross-platform (Windows/Linux) GUI **in v1**. A port to **Omarchy** (Arch Linux +
  Hyprland) is planned as **upcoming work** — tracked here, but not part of this
  workstream.
- No App Store distribution in v1.
- No cloud/account features. Local-first stays local-first.
- No new AI/runtime logic — the app only surfaces what the engine already detects.

## 4. Architecture

Three layers. **Only the third is new code.**

1. **Engine (unchanged)** — `src/sea_star/`. Vault detection, runtime + model
   autodetect, MCP server. Already complete.
2. **Bridge** — the app runs `sea-star ...` and parses a **machine-readable** result.
   The gap to close first is documented in §6.
3. **Cockpit (new)** — a SwiftUI app whose imperative edge is AppKit. SwiftUI
   `MenuBarExtra` renders the popover but exposes **no** right-click hook, so the status
   item is owned directly: `@main enum SeaStarMain` → `AppDelegate` (`NSStatusItem` +
   `NSPopover`), and the popover/settings views are the *same* SwiftUI views hosted in
   `NSHostingController`. Files split by responsibility: `App/`, `Views/`, `Models/`,
   `Services/`, `Support/`.

Engine internals the app leans on:

- **Vault resolution order** — `SEASTAR_VAULT` env > `seastar.toml [vault]` > Obsidian
  autodetect > fail loud — in
  [load_config()](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/config.py#L219-L231),
  with the Obsidian reader in
  [detect_vault()](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/config.py#L177-L207).
  The app surfaces the *chosen* vault and offers other known vaults as a pick-list.
- **Runtime autodetect** — `KNOWN_RUNTIMES` in `config.py` names the known harnesses
  (osaurus 1337, ollama 11434, lmstudio 1234, unsloth 8888, llamacpp 8080, **omlx 8000**,
  vllm 8000), but detection does **not** trust one address per harness: `scan_ports()` sweeps
  those ports plus `EXTRA_SCAN_PORTS` (8009, 5000, 9000, …) on `127.0.0.1`, and each responder
  is named by its `owned_by` (oMLX says `"omlx"`) → known port → `"local"`. `SEASTAR_SCAN_PORTS`
  overrides the set.
- **Bridge** — `doctor --json` emits a machine-readable status object; human output stays
  the default ([cli.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/cli.py#L65-L127)).
  The contract is §6.
- **Tool scoping** — each `[[mcp.servers]]` entry may carry `include`/`exclude`, and
  [MCPServerSpec.allows()](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/config.py#L62-L72)
  filters the bridged tool list at connect time inside `list_external_tools()`
  ([mcp_client.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/mcp_client.py)).
  This is D8; the app surfaces it read-only for now.

## 5. Decisions

**Locked (from the founder / handover):**

| # | Decision | Value |
| --- | --- | --- |
| D1 | Form factor | Menu-bar app (SwiftUI `MenuBarExtra`); optional main window later |
| D2 | Engine link | Shell out to the existing `sea-star` CLI; do not rewrite the engine |
| D3 | Graph view | Embed the codebase-memory web UI via `WKWebView`, restyled to the palette |
| D4 | Theme | **Carpet Sea Star** (*Meridiastra calcar*) — see §7 |
| D5 | Machine surface | Machine-readable bridge preferred over scraping rich text |
| D6 | App location | `macapp/` subfolder of this repo *(was P1; confirmed)* |
| D7 | Bridge name | `sea-star doctor --json`; human output stays the default *(was P2; confirmed)* |
| D8 | Tool surface | Per-server `include`/`exclude` allowlist/denylist, applied at connect time *(B; implemented)* |
| D9 | Instruction tracks | **Two first-class tracks** — GUI-first (zero terminal, the default) and terminal-first (CLI parity); neither is "advanced" *(founder directive)* |
| D10 | Identity & naming | Repo **`Roqett/Sea-Star`** (personal — keeps history on the founder's profile; *not* a GitHub org); licence name **Up Periscope**; bundle id **`UpPeriscope.Sea-Star`** (Apple Developer account, independent of GitHub) |

**Proposed (in this spec; confirm before scaffolding):**

*P1 (app location) and P2 (bridge name) were confirmed and promoted to D6/D7.*

| # | Decision | Proposal | Rationale |
| --- | --- | --- | --- |
| P3 | Icon source | Founder supplies via Apple's **Icon Composer**; app ships a monochrome template fallback | Founder offered to produce icon files; template fallback avoids a blocker. |
| P4 | Menu-bar icon | Monochrome template image (black/white), auto-tinted by the system | Apple protects the coloured top-bar treatment; a template image is the correct, native approach. |

## 6. Interface contract — the bridge

The GUI never scrapes human-formatted text; it calls `doctor --json` and decodes the
object. **Status: implemented (interim shape). The GUI-specific fields below are still
outstanding.**

**Command:** `sea-star doctor --json`.

**Implemented shape** (as of this revision, from
[cli.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/cli.py#L65-L127)):

```json
{
  "ready": true,
  "version": "0.1.0",
  "vault": "/Users/lono/Vaults/main",
  "notes": 1234,
  "runtime": "osaurus",
  "base_url": "http://127.0.0.1:1337/v1",
  "model": "foundation",
  "models": ["foundation"],
  "servers": [
    { "name": "obsidian", "command": "npx", "include": [], "exclude": [] }
  ]
}
```

On a `ConfigError` it prints `{"ready": false, "error": "..."}` and exits `1`. The
`servers` array is D8 surfaced for the app to display.

**Still required before the GUI can be built** — the interim object is flatter than the
GUI needs:

| Need | For | Status |
| --- | --- | --- |
| `vault.candidates` (other Obsidian-known vaults) | the vault pick-list (§8.1) | missing |
| `vault.source` (`obsidian` / `toml` / `env`) | telling the user *why* that vault won | missing |
| `server.state` (`stopped` / `running`) | the start/stop toggle (§8.4) | missing — but the app owns the process, so this may be local app state rather than bridge data; decide at T2.x |
| `schema_version` | an additive, versioned contract | missing |

Reshaping `vault` into an object (`{path, source, note_count, candidates}`) is part of
that work; the flat keys above are the interim contract.

**Rules:**

- Exit code `0` when a vault is resolved and a runtime answers; non-zero with a populated
  `error` field otherwise (fail loud, consistent with the engine).
- Stable key names; additive changes only, versioned via a `schema_version` field.
- Human `doctor` output stays the default; `--json` is opt-in.

## 7. Design system

**Theme — Carpet Sea Star.** Chosen because it is local to the founder's coast (Yorke
Peninsula / South Australia), eight-armed like the octopus in the existing logo, and its
near-infinite genetically-driven colourways mirror the product ethos — every user's setup
adapts to *their* rockpool.

**Visual rule: cold, dark canvas + bright glowing accents** — the codebase-memory graph's
feel, lit from the rockpool palette.

| Role | Colour | Hex |
| --- | --- | --- |
| Canvas / ink | near-black blue | `#10131A` |
| Deep purple | — | `#4B2E83` |
| Plum / maroon | — | `#7A1F3D` |
| Mauve | — | `#B0859E` |
| Electric blue | — | `#2F7FE0` |
| Teal | — | `#26A69A` |
| Neon green | — | `#8BD450` |
| Vermilion | — | `#E2402A` |
| Orange | — | `#F5842B` |
| Bone / cream | — | `#EDE3D2` |

**Material — Liquid Glass (macOS 27 / iOS 26+):**

- Adopt the system glass material rather than hand-rolled blur. Use `glassEffect` on the
  popover/control surfaces; group related glass elements with `GlassEffectContainer` and
  give them matching IDs via `glassEffectID` for correct morphing.
- Apply glass to the **navigation/control layer only** — not to content. Use it sparingly;
  overuse is the documented failure mode.
- Prefer the default "regular" variant; use "clear" only where a stronger content
  contrast is needed.
- Let the dark canvas (`#10131A`) show through so the accents read as *glowing*.

**Menu-bar icon (D4/P4):**

- **Monochrome template image** (`isTemplate = true`). The system tints it for light/dark
  and the active menu-bar state. No colour in the top bar — Apple protects that treatment.
- The **detailed starfish** cut is the mark — the same art as the popover header, so the two
  surfaces cannot drift. The bare cut's eight spokes read as a **snowflake** (a loaded word in
  the US market), so the mark draws a **solid band partway out from the fuzzy centre**: a
  sea-star's body with the ray tips left free. That gives it a centre of mass without hardening
  into a **cog**'s rim — neither shape is acceptable. A subtle variant/shape shift may signal
  "running" vs "stopped" (state conveyed by form, not colour).
- App icon (Dock/Finder) is distinct from the menu-bar icon and is layered per Icon
  Composer; colour is allowed there.

**Sea-star references (founder's explicit guidance):**

- Keep mosaic sea-star references **subtle** — *"we don't want to have fully carpet mosaic
  starfish all through it."* It should echo the codebase-graph graphic style, not carpet
  the UI. Use it as a restrained motif (e.g. node colouration, a quiet background trace),
  not as a repeated wallpaper pattern.

## 8. What v1 does

On launch / on click of the menu-bar item:

1. **Vault** (§8.1) → show the detected vault; offer the other Obsidian-known vaults to
   switch, filterable, plus **Open folder…** to adopt any folder at all.
2. **Harness** (§8.2) → run autodetect and show what answered ("oMLX — found", "Ollama — found").
3. **Model** (§8.3) → list the models the *selected harness* reports; click to choose.
4. **Go** → one button to start/stop the server; show state at a glance.

The popover is a **column with a scrolling body**: the header and the start/stop controls stay
pinned, and everything between them scrolls when there is more to say than fits. The reading the
person chose sets the column's rooms — the **rows** stay in a 340pt column, while the **starfield
opens wider and taller (~460pt square)** so the harnesses on its right edge and the tip note beside
the active starfish have space (§8.7). The reading is only open for a moment, so it may be large;
the middle gets a definite height (not a flexible max) so the popover opens whole rather than
clipping itself, and it is clamped only to keep the bottom on-screen.

Menu-bar item text stays short (≤ ~30 characters); push detail into the popover or a
window.

### 8.1 Vault — browse and search

The vault row is a menu of `report.vault.candidates` (the current vault always included,
even when it came from env/TOML). Because a person may keep vaults Obsidian has never
seen, the menu carries **Open folder…**, which raises a folder picker; the chosen path is
pinned via `SEASTAR_VAULT`. The **Settings window** (§8.4) adds a searchable, scrolling
list of the same candidates for machines with many vaults.

### 8.2 Harness — one row per live endpoint

`runtimes[]` gives one entry per live harness; each is labelled `name · baseURL` (an
endpoint alone cannot say which app answers on a shared port). Switching pins
`SEASTAR_BASE_URL` + `SEASTAR_RUNTIME` and clears any model override, since the previous
model may not exist on the new endpoint.

### 8.3 Model — follows the selected harness

The model row lists the **selected harness's** own models (from `runtimes[]`), falling back
to `report.models`; the current model is kept first. This is what makes a model served only
by one harness (e.g. a Qwen model behind oMLX) appear as soon as that harness is chosen.
Switching pins `SEASTAR_MODEL`.

### 8.4 Settings window (the configuration surface)

The right-click menu's **Settings…** opens a proper window (not the popover) — the "must
have" the founder asked for, kept deliberately simple but complete:

- **Engine** — whether `sea-star` resolved, where it points, and the fix (`SEASTAR_CLI`)
  when it did not.
- **Vault** — the current path, a **search field**, a scrolling list of every candidate
  (current one ticked), and **Open folder… / Use detected vault**.
- **Harness / Model** — the same two choices as the popover, as pickers.
- **Updates** — check now, with the result inline; the bundled version is always shown.
- **Links** — Help & Comments (issues), Patchdog, and the repository.

### 8.5 Update check (GitHub Releases)

**Check for Updates…** (in the right-click menu and in Settings) asks the GitHub Releases
API for `Roqett/Sea-Star`'s latest release, compares it to the bundled
`CFBundleShortVersionString` as dotted numbers (a leading `v` and ragged segment counts are
tolerated), and — only when the release is genuinely newer — offers to open its page. On a
network failure it says so plainly; it never blocks the app.

### 8.6 Right-click menu (the standard app menu)

An accessory (`LSUIElement`) app has no menu bar of its own, so the standard app menu lives
on the status item's **right-click** (and ⌃-click): **Check for Updates…**, a separator,
**Settings…** (⌘,), **Help & Comments**, **Patchdog**, a separator, a disabled
**Version `<version> (<build>)`** line, a separator, and **Quit Sea-Star** (⌘Q). Left-click
still opens the cockpit popover. Patchdog is the planned GitHub agent for comments/issues;
until it exists the item points at a placeholder URL.

### 8.7 Entity graph (the "starfield" view)

Some people read the cockpit's rows; some prefer to *see* the shape of the thing. The header
carries a **mode toggle** — two SF Symbols (connected points for the graph, a bulleted list for
the rows), lit the way Apple lights a segmented control — sitting **up with the "ready" pill and
the gear**. On **first launch** the popover asks which reading to open with (either choice is
fine) and remembers the answer in `UserDefaults` (`SeaStar.cockpitMode`); thereafter the header
icons swap between the two readings of the same facts. Until a preference exists, the graph is
shown behind the question and neither icon is pressed.

The starfield opens a **larger panel than the rows do** — roughly 460pt square against the rows'
340pt column. It needs the width so the harnesses down the right edge and the tip note beside the
active starfish stop crowding the frame, and the height so the orbs have room to drift (spec §8).

The graph draws the roster as glowing nodes on a dark backdrop — the **vault** off to the
left, each **harness** down the right edge, and the active harness's **models** ringing it.
Colour is meaning, not decoration: vault `teal`, harness `electricBlue`, model `neonGreen`
(the same accents the list rows carry). Hovering or selecting a node reveals its name and
detail; tapping a node selects it through the same `selectVault` / `selectHarness` /
`selectModel` calls the list uses, so the two views can never disagree.

The **connection** between the vault and the active harness is drawn as a nudibranch strip
(`NudiStrip.expands == false`, fixed length), rotated to sit between the two nodes — the 3px
ribbon grown up into the wiring of the app. It *grows out of the vault* whenever the active
harness changes, so the strip visibly shoots at the thing it just connected to. The orbs drift on
a slow current and their glow breathes; all of that stills under Reduce Motion.

A short **note** grows beside the active starfish, and tapping that starfish expands and contracts
it. `HarnessTips.tip` (pure, unit-tested) decides what, if anything, to say, in priority order: a
harness the person has **never been on** gets a setting-up hint ("you'll likely need to configure
this"); failing that, **other vaults nearby** raise a wrong-vault nudge; failing that, a known,
ready harness gets the quiet "connected — *n* models on offer" line. Seen harnesses are remembered
in `UserDefaults` (`SeaStar.seenHarnesses`, keyed by endpoint) and a fresh hint is acknowledged
with **Got it**, after which the note settles into the connected line.

### 8.8 Logs (kept short on purpose)

The cockpit exposes the engine's own output in a collapsible **Logs** panel: the blue-white
nudibranch strip borders it top and bottom, the body is SF Mono, selectable, and inked in the
matching blue (`Palette.logInkDark` / `logSurfaceDark` for the always-dark rockpool canvas;
`logInkLight` / `logSurfaceLight` are defined for an adaptive surface). Engine `stdout` and
`stderr` are piped into a single `LogStore`, so the lines are durable rather than transient.

A menu-bar helper has no business letting logs pile up on the disk for years. `LogStore`
**prunes on every write** against a retention window the person chooses in Settings →
**Logs** (default **14 days**; options Forever / 7 / 14 / 30), keeps a single small file at
`~/Library/Logs/Sea-Star/sea-star.log`, and offers **Clear now** and **Reveal in Finder**.
The retention rule is a pure function (`LogStore.retained`) so it is unit-tested without a
clock or a disk.

## 9. Build, sign, release

**Verified toolchain on this machine:** Xcode 27.0 (Build 27A266a), Swift 6.4, macOS 27;
`xcodebuild`, `codesign`, `xcrun notarytool` and `stapler` all present. Node v26.9.0 /
npm 11.19.1.

- **Local build (founder):** `xcodebuild` against the generated `.xcodeproj`/workspace,
  or `swift build` for the non-UI parts. Local builds need no signing.
- **Distribution (other people):** requires a paid Apple Developer account →
  `codesign` (Developer ID) → `xcrun notarytool submit --wait` → `xcrun stapler staple`.
  The founder has the account — the Xcode New-Project sheet shows Team **NICHOLAS BLADES
  BICKFORD**, so a signing identity is already in place — and will run the final pass
  through Xcode.

### 9.1 Automation — the native Xcode MCP path *(corrected in revision 2)*

The earlier claim that macOS must be built shell-first *"because the connected plugin is
iOS-only"* was **wrong** and is retracted. Xcode 27 ships its own MCP surface, and it is
**not** the third-party `xcodebuildmcp` package:

- **`xcrun mcpbridge`** — Apple's *STDIO Bridge for Xcode MCP Tools*. Reads JSON-RPC 2.0 on
  stdin, writes to stdout; identifies as `xcode-tools` **v25317** and exposes **54 tools**
  (project/target/scheme management, build, run, tests, previews, entitlements, string
  catalogs, debugger, file ops).
- **`xcrun mcp-server`** — the headless manager. Subcommands: `open`, `stop`, `enable`,
  `disable`, `approve`, `deny`, `allow-folder`, `clear-permissions`, `reset-all`, `status`,
  `show-logs`. `status --format json` reports open workspaces, permission and running state;
  logs land in `~/Library/Logs/Xcode/XcodeService/`.
- **`xcrun mcpbridge run-agent <agent>`** — launches a coding agent with Xcode-provided
  config/skills (`--dry-run`, `--no-xcode-tools`; agents incl. `claude`, `codex`,
  `antigravity`).

**Three requirements — verified.** (1) The Xcode **tool service** running — it runs
**headless**; `mcp-server status` reported `running` with Xcode.app **fully quit**. (2) **A
workspace open** — `Xcode tools require an open workspace`; this is the usual blocker.
(3) The MCP client must **hold the pipe open** — closing stdin immediately yields a silent
`rc 1` with no output. **Xcode.app itself does not need to be open.**

The third-party **`xcodebuildmcp`** package (latest `2.7.0`, run here as
`npm exec xcodebuildmcp@latest mcp`) stays useful for iOS/Simulator work but is **not**
required for this macOS app.

## 10. Two ways in — GUI-first and terminal-first

The founder is allergic to the terminal; plenty of other people live in it. Both audiences
are served as **first-class, equally-easy tracks** (D9). Neither is the "advanced" one.
Every GUI action has an exact CLI equivalent, and the two tracks are kept in lockstep.

### 10.1 GUI-first track *(default — the founder's path)*

Zero terminal, end to end:

1. **Install** — copy `Sea-Star.app` to `/Applications` (local build) or download the
   notarised build.
2. **Launch** — click the monochrome star in the menu bar.
3. **Detect** — the popover shows the resolved vault, the harness that answered, and the
   current model.
4. **Choose** — switch vault from the Obsidian-known pick-list; switch model from the
   endpoint's list.
5. **Go** — one button starts/stops the server; state is visible at a glance.

If something is missing (no vault, no runtime), the app says so in plain language and
points at the fix — it never drops the user into a shell.

### 10.2 Terminal-first track *(contributors and CLI-comfortable users)*

The same engine, driven directly. Full parity with the GUI:

| GUI action | Terminal equivalent |
| --- | --- |
| Detect (vault / harness / model) | `uv run sea-star doctor` |
| Machine-readable status | `uv run sea-star doctor --json` |
| Start the MCP server | `uv run sea-star serve` |
| Create `seastar.toml` | `uv run sea-star init` |
| Ask the vault a question | `uv run sea-star ask "…"` |
| Keep the engine green | `uv run ruff check . && uv run pytest` |

### 10.3 Keeping the tracks in sync

- A change to one track is a change to the other; the §10.2 parity table is the contract.
- The two tracks sit beside each other (GUI-first first, terminal-first second) so a reader
  self-selects at a glance.
- Docs tasks T6.1–T6.3 own this.

## 11. Acceptance

See [checklist.md](file:///Users/lono/Random_MCP/theSeaStar/.trae/specs/mac-app/checklist.md).
Top-level: the founder can complete detect → choose → start → stop without ever opening a
terminal, a terminal-comfortable user can do the same entirely from the CLI (§10), and the
engine's 27 tests stay green.

## 12. Risks / open questions

- **Bridge is interim, not final** — `doctor --json` currently emits a flat object; the GUI
  needs `vault.candidates`, `vault.source`, `server.state` and `schema_version` before
  Phase 2 can rely on it (§6).
- **CLI parsing brittleness** — mitigated by the §6 JSON contract; never scrape rich text.
- **Graph index is stale** — the codebase-memory index (252 nodes / 814 edges) predates the
  rename and still shows `src/seastar/...`. Re-index before trusting paths in the embedded
  graph.
- **Reference images are third-party** and git-ignored on purpose. They must not be pushed
  publicly; only the palette/rationale ships. Filenames are listed in
  `assets/reference/README.md` (directory may be absent from a fresh clone).
- **Liquid Glass overuse** is a real failure mode — keep it to the control layer.
- **Bridge schema drift** — the interim keys are already live; freeze the final shape (§6)
  and version it with `schema_version` before the app depends on it.
- **Tool scoping is static by design** — `include`/`exclude` are a connect-time allowlist,
  not a query-time router. If a bridged server exposes dozens of tools, curate it
  explicitly rather than letting the menu grow.
- **Xcode MCP fails silently** — the native bridge answers only when a workspace is open,
  and only if the client keeps stdin open; otherwise it returns `rc 1` with no output. A
  headless/CI run must `xcrun mcp-server open <workspace>` first (§9.1).
- **Two instruction tracks can drift** — GUI-first and terminal-first must move together;
  the §10.2 parity table is the contract, checked at release (T6.3).

## 13. Dev environment (this machine)

- **Inference:** Osaurus on `http://127.0.0.1:1337/v1`, model `foundation` (Apple
  on-device). `sea-star doctor` prints **Ready**. oMLX defaults to
  `http://localhost:8000/v1`.
- **codebase-memory graph UI:** running at `http://localhost:9749`
  (`codebase-memory-mcp --ui=true --port=9749`). Index is stale — re-index first.
- **Vault:** autodetected from Obsidian; a throwaway `demo-vault/` is used for testing.
- **Xcode MCP (headless):** `xcrun mcp-server status` reports `running` even with Xcode.app
  closed. To exercise the bridge, open a workspace first (`xcrun mcp-server open
  <ws>`) and hold stdin open. Clear any throwaway workspace registration when done.

## 14. Cheat sheet

```bash
uv run sea-star doctor      # human-readable readiness check
uv run sea-star doctor --json   # the bridge contract (machine-readable)
uv run sea-star serve       # run as an MCP server (stdio)
uv run ruff check . && uv run pytest   # keep green before committing
open http://localhost:9749  # codebase-memory graph UI (if running)
xcrun mcp-server status     # is the headless Xcode tool service up?
xcrun mcp-server open Foo.xcworkspace   # open a workspace for the MCP bridge
xcrun mcpbridge             # STDIO bridge to Xcode's MCP tools (xcode-tools, 54 tools)
```

Build commands and project protocol: `AGENTS.md`.
