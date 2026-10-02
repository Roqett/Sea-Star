# Sea-Star — Mac app handover

Handover for a **new session** picking up the Mac GUI workstream. Read this top to
bottom before touching anything. The Python engine is done and green; this document
is about building a native macOS front end on top of it.

## 1. Where we are

- **Product:** Sea-Star — a free (MIT), local-first, runtime-agnostic MCP server that
  turns an Obsidian vault into a private AI agent. Repo **`Roqett/Sea-Star`** — stays under
  the founder's personal account (keeps the history on his profile); "Up Periscope" is the
  **product identity** (licence + bundle id), not a GitHub org (dist package `seastar-mcp`).
  Public goal: "one-click, just works" for everyone.
- **Founder:** "Lono" (GitHub `Roqett`), ex-winemaker in McLaren Vale,
  South Australia.
  Comfortable with Swift basics only — **allergic to the terminal**. This is the whole
  reason the GUI exists.
- **Engine state:** `uv run ruff check .` clean; `uv run pytest` → 97 passing. Version
  `0.1.0`, unreleased. The **app bridge (`sea-star doctor --json`), `include`/`exclude`
  tool curation, and the stdio connection records (§7 note below) are all in** — the engine
  surface the app needs exists. The app itself is **built and running**: Swift suite → 70
  cases in 13 suites, green. Branch `feat/macapp-cockpit`.
  *This section was rewritten 2026-10-02; it previously cited 27 tests and HEAD `f4d21b3`
  on `main`, both long superseded. `docs/PROGRESS.md` is the live record — trust it over any
  figures quoted in this document.*
- **Local folder:** `/Users/lono/Random_MCP/theSeaStar` (folder name still the old
  spelling; the repo and package are already `Sea-Star` / `sea_star`).

## 2. The new workstream, in one line

Build a **lightweight, native macOS menu-bar app** that wraps the existing Python
engine so the founder never has to open a terminal — it flashes up what it finds
(vault, harness, model) and he clicks.

## 3. Decisions locked (from the founder)

1. **Form factor:** a **menu-bar app** (SwiftUI `MenuBarExtra`) — click the star, get a
   compact popover. Optionally a matching main window later.
2. **Engine link:** the app **shells out to the existing `sea-star` CLI** and reads the
   output. Do **not** rewrite the Python engine. Keep the Python tests green (currently 97).
3. ~~**Graph view:** embed the existing codebase-memory web UI in a web view
   (`WKWebView`) so the app shows that exact bright graph, restyled in the Sea-Star
   palette.~~ **Superseded — the graph was built natively instead.** The cockpit draws its
   own entity graph: a **Flat** 2D starfield (`EntityGraphView.swift`) and a **Deep**
   SceneKit room (`GraphScene.swift` / `GraphSceneView.swift`), both fed by one
   renderer-independent `EntityGraphModel.swift` so the two readings and the list rows can
   never disagree (`DECISIONS.md` D-002; spec §8.7/§8.8). No web view, no `WKWebView`, and
   **no runtime dependency on codebase-memory** — that project is now a *visual reference*
   only (its look, and `assets/reference/ui-codebase-memory-graph.png`), not infrastructure.
   The colour rule in §5 below still stands unchanged.
   *Superseded 2026-10-02. The same stale line is still in the spec's locked table as **D3**;
   that is a founder-only amendment and has been flagged rather than edited (see
   `docs/PROGRESS.md`, 2026-10-01/02 handoff). A **pending, undecided** founder note asks
   whether a *bundled, offline* web canvas (`3d-force-graph`, local files, no network) might
   replace the SceneKit room — which is a different proposition from this old plan and is
   deliberately not pre-empted here.*
4. **Theme:** the **Carpet Sea Star** (*Meridiastra calcar*) — see §5.

## 4. Architecture

Three layers. Only the third is new code.

1. **Engine (unchanged):** `src/sea_star/`. Already handles vault detection, runtime +
   model autodetect, and the MCP server.
2. **Bridge:** the app runs `sea-star ...` and parses the result. **Gap closed:**
   `sea-star doctor --json` now emits one JSON object (`schema_version`, a nested
   `vault {path, source, note_count, candidates}`, `mcp_clients[]`, `latent_harnesses[]`,
   `runtimes[]`, bridged `servers`) and always emits JSON, even on failure — see
   [cli.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/cli.py). The
   human output stays the default. The app decodes this object rather than scraping rich
   text, and `tests/test_cli.py` now covers it (spec T1.5). **One field is known-stale:**
   `server.state` is derived from whether the *inference endpoint* answered, not from
   whether the MCP server is running — the app ignores it and tracks the real state itself
   (`ServerController.isServerRunning`). See `docs/PROGRESS.md`, 2026-10-01/02 handoff.
3. **Cockpit (built):** a SwiftUI app under `macapp/` (XcodeGen project). Started as
   `MenuBarExtra`, and is now **AppKit-hosted SwiftUI** (`SeaStarMain` → `AppDelegate`,
   `NSStatusItem` + `NSPopover`) because the popover behaviour needed AppKit. Files are split
   by responsibility: `App/`, `Views/`, `Models/`, `Services/`, `Support/`, `Shaders/`.

Useful existing internals to lean on:
- Vault resolution order — `SEASTAR_VAULT` env > `seastar.toml [vault]` > Obsidian
  autodetect > fail loud — is in
  [config.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/config.py#L202-L214), with
  the Obsidian reader in
  [detect_vault()](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/config.py#L160-L190).
  The app should surface the *chosen* vault, and offer the other known vaults as a pick-list.
- Runtime autodetect is `KNOWN_RUNTIMES` in `config.py` (osaurus 1337, ollama 11434,
  lmstudio 1234, unsloth 8888, llamacpp 8080, **omlx 8000**, vllm 8000; oMLX probed first).
  Detection actually sweeps a standard localhost port set (`scan_ports()` + `EXTRA_SCAN_PORTS`)
  rather than one address per harness, so a harness on a non-default port (oMLX on 8009) is
  still found; responders self-identify via `owned_by`.

## 5. The look — Carpet Sea Star

Why this star: it is **local to the founder's own coast** (Yorke Peninsula / South
Australia), it is **eight-armed** like the octopus in the existing logo, and its
**near-infinite, genetically-driven colourways** mirror Sea-Star's ethos — every user's
setup adapts to *their* rockpool. No two look alike.

Visual rule: **cold, dark canvas + bright glowing accents.** Same feel as the
codebase-memory graph (see `assets/reference/ui-codebase-memory-graph.png`), but lit
from the rockpool palette:

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

Ideas to explore: the menu-bar icon is the eight-armed star (optionally hue-shifting
like a variant); graph nodes take their colour from this palette; each install may pick
its own "colouration" so *your* Sea-Star looks like *your* star.

Reference photos live in `assets/reference/` (**git-ignored on purpose** — third-party
photos, must not be redistributed in a public repo). Filenames are listed in
`assets/reference/README.md`. Note: the copies on disk are low-res thumbnails
recovered from chat; replace with full originals when possible. The palette above is
the durable record.

## 6. What v1 should do

On launch / on click:

1. **Vault** → show the detected vault; offer the other Obsidian-known vaults to switch.
2. **Harness** → run autodetect and show what answered ("oMLX — found", "Ollama — found").
3. **Model** → list the models the endpoint reports; click to choose.
4. **Go** → one button to start/stop the server; show state at a glance.

Menu-bar item text stays short (≤ ~30 chars); push detail into a window or popover.

## 7. This machine (dev environment)

- Inference: **Osaurus** on `http://127.0.0.1:1337/v1`, model `foundation`. `sea-star
  doctor` prints **Ready**. oMLX defaults to `http://localhost:8000/v1`.
- *Removed 2026-10-02:* this section used to say the codebase-memory graph UI "is already
  running" at `http://localhost:9749` and that Sea-Star was indexed there. **Nothing depends
  on it.** The cockpit's graph is drawn natively from `EntityGraphModel`, and no Swift or
  Python file references `9749` or codebase-memory. If that UI happens to be running it is
  useful only as a visual reference; it is not part of the build, the run, or the tests.

## 8. Suggested first steps

**All five of the original steps are done** — the app is scaffolded, the popover is wired to
the bridge, the theme is applied, and the graph shipped natively (step 4 was built as a native
renderer, not the `WKWebView` originally proposed; see §3). Kept here corrected rather than
deleted, so a reader is not sent to build something that exists:

1. ~~Add the machine-readable bridge~~ — **done**: `sea-star doctor --json` ships, and now
   carries `mcp_clients[]` as well (see `docs/PROGRESS.md`).
2. ~~Scaffold the SwiftUI menu-bar app~~ — **done**: `macapp/`, AppKit-hosted (`AppDelegate` +
   `NSStatusItem`/`NSPopover`), with a `Services/` CLI client that runs the command and decodes
   the JSON.
3. ~~Static first pass: popover showing vault / harness / model + start-stop toggle~~ — **done**,
   themed with the §5 palette, and grown well past a static pass.
4. ~~Add the embedded graph~~ — **done natively**: Flat 2D starfield + Deep SceneKit room over
   one `EntityGraphModel`. No `WKWebView`.
5. ~~Then polish: colouration picker, the star icon, the founder's live feedback~~ — **done and
   ongoing**: four-face icon roster, caustic shimmer, hover readout, focus mode.

**Where to actually start now:** `docs/PROGRESS.md` → the most recent handoff's "OPEN" list.
That file, not this one, tracks outstanding work.

## 9. Open questions / risks

- **Where does the app live?** Separate repo (e.g. `Roqett/Sea-Star-mac`) or a subfolder
  of the current repo? Decide before scaffolding.
- **Distribution:** a real one-click download for *other people* needs Apple
  code-signing + notarisation (paid account). For the founder, a local build is enough
  to start.
- **Reference images are third-party** — keep them out of any public push (already
  git-ignored). Only the palette/rationale should ship.
- **CLI parsing brittleness:** prefer the `--json` route over scraping rich text.

## 10. Cheat sheet

```bash
uv run sea-star doctor      # human-readable readiness check
uv run sea-star doctor --json   # the bridge contract the app decodes
uv run sea-star serve       # run as an MCP server (stdio)
uv run ruff check . && uv run pytest   # engine: keep green before committing
script/build_and_run.sh     # app: regenerate project.yml via XcodeGen, build, launch
```

Build commands and project protocol: `AGENTS.md`. Live build state: `docs/PROGRESS.md`
— that file is the source of truth for what is outstanding; this document is wayfinding.