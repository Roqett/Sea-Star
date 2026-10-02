# Sea-Star — reference sheet

> **Not a README.** A distillation for cross-checking with other models — **. Kept in `docs/`, git-tracked locally / on Codeberg,
> **not pushed to the GitHub repo**.

## What it is

A local-first AI agent over an Obsidian vault. It is an **MCP server that is also an
MCP client**.

- **MCP server** — exposes one tool, `ask_seastar`, to any MCP host.
- **MCP client** — can consume other MCP servers as its own tools.
- **Engine** — Python. Talks to any OpenAI-compatible local endpoint. No cloud, no telemetry.

## What it does

- Indexes an Obsidian vault and searches it.
- Runs a local agent loop: plan → tool call → answer.
- Answers with `[[wikilinks]]` citations back to the notes it used.
- Finds a local runtime and a vault with zero config.

## What it solves
**A central MAC OS Menu bar AI agentic Cockpit : WHOs running , with WHAT  model , WHERE and WHEN ..** TRACKING AT a place , GRAPHICALLY OR TEXTually 

- **Setup cost** — local agents today are a weekend of YAML and silent failures. Here it's one command.
- **Privacy** — frontier agents are cloud and read your notes. This runs on your machine.
- **Vault-as-memory** — wiring Obsidian + a local model + an agent loop is left to the reader everywhere else. Here it *is* the product.

## What it de-complicates (less braintax)

- **Runtime choice** — one OpenAI-compatible contract; Osaurus, Ollama, LM Studio, llama.cpp, MLX, vLLM and Unsloth all work unchanged.
- **Vault discovery** — reads Obsidian's own `obsidian.json`; no path config needed.
- **Tool sprawl** — a per-server `include` / `exclude` allowlist keeps the agent's tool menu short enough to choose well.
- **Host choice** — the same `mcpServers` block works in Claude Desktop, Cursor, TRAE and Osaurus.

## What it achieves

- Cited answers drawn from your own notes, produced entirely on-device.
- A stable machine surface — `sea-star doctor --json` — that any front end can hang off.

## Port seams (for the Omarchy work)

| Layer              | Today                              | On Omarchy                                                            |
| ------------------ | ---------------------------------- | --------------------------------------------------------------------- |
| Engine             | Python (`src/sea_star/`)           | Runs unchanged, given a Linux runtime + Obsidian                      |
| Inference contract | OpenAI-compatible HTTP             | Unchanged                                                             |
| Vault contract     | Obsidian `obsidian.json` + Markdown | Unchanged (`~/.config/obsidian/obsidian.json`)                        |
| Machine surface    | `sea-star doctor --json`           | Unchanged — **this is the integration seam**                          |
| GUI                | SwiftUI (macOS)                    | **Rewrite.** SwiftUI has no Linux backend; the cockpit becomes a GTK4 / native Linux shell |

**Bottom line:** the rewrite is the GUI only. The engine, the inference contract and the
vault contract are portable as-is; the `doctor --json` bridge is the line the new front
end talks across.

## Commands (engine, as it stands)

```bash
sea-star init --vault <path>   # write seastar.toml
sea-star doctor                # human-readable readiness
sea-star doctor --json         # machine-readable readiness
sea-star serve                 # run as an MCP server (stdio)
sea-star ask "…"               # ask the vault directly
```
