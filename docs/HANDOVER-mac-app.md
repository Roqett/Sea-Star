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
- **Engine state:** `uv run ruff check .` clean; `uv run pytest` → 27 passing. Version
  `0.1.0`, unreleased. The **app bridge (`sea-star doctor --json`) and `include`/`exclude`
  tool curation are now in** — the engine surface the app needs already exists. Latest
  committed HEAD is `f4d21b3` on `main`; the bridge work sits on top of it.
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
   output. Do **not** rewrite the Python engine. Keep the 27 tests green.
3. **Graph view:** embed the existing codebase-memory web UI in a web view
   (`WKWebView`) so the app shows that exact bright graph, restyled in the Sea-Star
   palette.
4. **Theme:** the **Carpet Sea Star** (*Meridiastra calcar*) — see §5.

## 4. Architecture

Three layers. Only the third is new code.

1. **Engine (unchanged):** `src/sea_star/`. Already handles vault detection, runtime +
   model autodetect, and the MCP server.
2. **Bridge:** the app runs `sea-star ...` and parses the result. **Gap closed:**
   `sea-star doctor --json` now emits one JSON object (vault path, note count, runtime name,
   base URL, model, model list, bridged servers) and always emits JSON, even on failure —
   see [cli.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/cli.py#L64-L131). The
   human output stays the default. Still worth a test (spec T1.5); the app should decode
   this object rather than scrape rich text.
3. **Cockpit (new):** a SwiftUI app. Start with `MenuBarExtra`; keep the scene explicit
   and files split by responsibility (`App/`, `Views/`, `Models/`, `Services/`, `Support/`).

Useful existing internals to lean on:
- Vault resolution order — `SEASTAR_VAULT` env > `seastar.toml [vault]` > Obsidian
  autodetect > fail loud — is in
  [config.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/config.py#L202-L214), with
  the Obsidian reader in
  [detect_vault()](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/config.py#L160-L190).
  The app should surface the *chosen* vault, and offer the other known vaults as a pick-list.
- Runtime autodetect is `KNOWN_RUNTIMES` in `config.py` (osaurus 1337, ollama 11434,
  lmstudio 1234, unsloth 8888, llamacpp 8080, **omlx 8000**, vllm 8000; oMLX probed first).

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
- **codebase-memory graph UI is already running** at **http://localhost:9749**
  (`codebase-memory-mcp --ui=true --port=9749`). Sea-Star is indexed there (252 nodes /
  814 edges) but the index is **stale** — it predates the rename, so it still shows
  `src/seastar/...`. Re-index before trusting paths.

## 8. Suggested first steps

1. ~~Add the machine-readable bridge~~ — **done**: `sea-star doctor --json` ships. Add a
   test for it (spec T1.5), then move on to the app itself.
2. Scaffold the SwiftUI menu-bar app (own folder or sibling repo — decide this first):
   `MenuBarExtra` scene + a `Services/` CLI client that runs the command and decodes JSON.
3. Static first pass: popover showing vault / harness / model from the JSON, with a
   start-stop toggle. Theme it with the palette in §5.
4. Add the embedded graph (`WKWebView` → `http://localhost:9749`) in a detail window.
5. Then polish: colouration picker, the star icon, the founder's live feedback.

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
uv run sea-star serve       # run as an MCP server (stdio)
uv run ruff check . && uv run pytest   # keep green before committing
open http://localhost:9749  # codebase-memory graph UI (if running)
```

Build commands and project protocol: `AGENTS.md`. Live build state: `docs/PROGRESS.md`.