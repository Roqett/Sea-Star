# Changelog

All notable changes to Sea-Star are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
