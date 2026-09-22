<div align="center">

<img src="assets/seastar_sf.png" alt="The Sea Star — the octopus with the martini glass" width="300">

# ⭐ SeaStar

**A private, local-first AI agent that lives in your Obsidian vault.**
One-click's ease. Nothing leaves your house.

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Python 3.11+](https://img.shields.io/badge/python-3.11%2B-blue.svg)](https://www.python.org/)

</div>

---

> *"Your own adventure to fair winds and following seas."*
> — The Sea Star, 2289 3rd Street, Dogpatch, San Francisco
> This cute snack also thanks Tom's dry dock around the corner. As it was.

A sea star has an astal brain and clings to its rock.
SeaStar is the agent that clings to your notes — and helps your roq find the Right spot

---

## The problem

Right now you get to pick two of three:

- **Powerful local agents** (Goose, Aider, custom stacks) — but configuring them is a weekend of YAML and silent failures.
- **One-click agents** (the frontier products) — but they're cloud, proprietary, and they read your notes.
- **Your Obsidian vault as the brain** — but wiring Obsidian + a local model + an agent loop together is left as an exercise for the reader.

**SeaStar is the missing third option:** the zero-config, fully-local agent that treats your Obsidian vault as first-class memory, runs on whatever local model you already have, and plugs into whatever MCP host you already use.

## What it is

SeaStar is an **MCP server that is also an MCP client** — a slightly unusual beast, on purpose:

- As an **MCP server**, it exposes one simple tool (`ask_seastar`) to any host — Claude Desktop, Cursor, TRAE, whatever. That tool runs a full local agent loop.
- As an **MCP client**, it *consumes* other MCP servers — including the existing Obsidian ones — as its own tools.

The reasoning happens on **your** machine, against **your** model. The host is just a window.

## Why it stays sovereign

SeaStar talks to any **OpenAI-compatible** local inference endpoint. That means it works, unchanged, with:

| Runtime | Default endpoint |
| --- | --- |
| Ollama | `http://localhost:11434/v1` |
| LM Studio | `http://localhost:1234/v1` |
| llama.cpp (`llama-server`) | `http://localhost:8080/v1` |
| MLX (`mlx_lm.server`) | `http://localhost:8080/v1` |
| vLLM | `http://localhost:8000/v1` |
| Unsloth Studio | its OpenAI-compatible port |

Runtime-agnostic by contract. You never touch this layer again.

## The focused setup: Osaurus + Unsloth Studio

SeaStar is runtime-agnostic on purpose — but if you want the *specific* pairing that
inspired it, this is the one: **Osaurus for the agent layer, Unsloth Studio for the
model-and-skills layer, SeaStar for the memory.**

The two are complementary by nature. Osaurus is a Mac-native agent harness — it runs
agents, loads skills, and speaks MCP both ways. Unsloth Studio is a model workbench —
it runs and fine-tunes models and exposes an **OpenAI-compatible API**. Osaurus brings
the *doing*; Unsloth brings the *thinking*; neither one knows about your notes. SeaStar
is the third leg: it gives them a shared, private memory in your Obsidian vault.

```
┌────────────────────┐   MCP    ┌──────────────┐   OpenAI-compatible   ┌──────────────────┐
│  Osaurus (agents)  │ ───────▶ │   SeaStar    │ ────────────────────▶ │ Unsloth Studio   │
│  skills, memory    │ ◀─────── │  (memory)    │ ◀──────────────────── │ (local models)   │
└────────────────────┘          └──────┬───────┘                       └──────────────────┘
                                       │
                                       ▼
                              ┌──────────────────┐
                              │  Obsidian vault  │
                              └──────────────────┘
```

**The recipe (three moves):**

1. **Start the engine.** In Unsloth Studio, launch the local server and copy its
   OpenAI-compatible base URL (the same kind of URL as Ollama's `…:11434/v1`).
2. **Point SeaStar at it.** Put that URL and the model name in your `seastar.toml`
   under `[inference]` — see Configuration below. That's the whole "Unsloth is the brain" step.
3. **Point Osaurus at SeaStar.** Add SeaStar as an MCP server in Osaurus (the same
   `command` / `args` block you'd add to Claude Desktop). Osaurus now has your vault
   as memory; its agents can ask SeaStar what you already know.

> Menu labels drift between versions of both apps — the *concept* is what matters:
> Unsloth serves an OpenAI-compatible endpoint, SeaStar consumes it, Osaurus calls SeaStar.
> If either app exposes a compatible endpoint, this works unchanged.

And if you'd rather use a different harness tomorrow — LM Studio, Ollama, Claude
Desktop — **nothing above changes.** That flexibility is the point.

## Install

```bash
# Zero-install from source, if you have uv (recommended):
uvx --from git+https://github.com/Roqett/theSeaStar seastar serve

# Or clone and run it locally:
git clone https://github.com/Roqett/theSeaStar
cd theSeaStar
uv sync
uv run seastar serve
```

> `pip install seastar-mcp` lands with the first PyPI release. Until then, the
> `uvx --from git+...` form above is the one-liner to use.

## Quickstart

```bash
# 1. Point SeaStar at your Obsidian vault
seastar init --vault "~/Documents/MyVault"

# 2. Check that it can see a local model
seastar doctor

# 3. Run it as an MCP server (stdio)
seastar serve
```

Then add it to your MCP host of choice:

```json
{
  "mcpServers": {
    "seastar": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/Roqett/theSeaStar", "seastar", "serve"]
    }
  }
}
```

Ask your host: *"Ask SeaStar what I decided about the vineyard irrigation project."*
SeaStar searches your vault, reasons locally, and answers **with citations to your own notes**.

## Configuration

SeaStar is zero-config by default: it auto-detects common local runtimes **and**
finds your Obsidian vault straight from Obsidian's own `obsidian.json`, so for most
people `seastar serve` just works with no setup at all.

If you want to pin things down, `seastar init --vault <path>` writes a `seastar.toml`
**into your vault**. SeaStar also reads `./seastar.toml` from the working directory and
`~/.config/seastar/config.toml`. Resolution order is: explicit path → `SEASTAR_*`
environment variables → config file → autodetection → a loud failure.

```toml
# <your-vault>/seastar.toml
vault = "/Users/you/Documents/MyVault"

[inference]
# Leave base_url empty to let SeaStar autodetect a local runtime on startup.
base_url = "http://127.0.0.1:11434/v1"   # any OpenAI-compatible endpoint
model = "qwen2.5:7b-instruct"
api_key = "seastar-local"                # local runtimes ignore this
max_steps = 8
temperature = 0.2

# Consume other MCP servers (e.g. an Obsidian MCP) as SeaStar's own tools.
[[mcp.servers]]
name = "obsidian"
command = "npx"
args = ["-y", "obsidian-mcp", "/Users/you/Documents/MyVault"]
```

## How it works

```
┌──────────────────┐        MCP (stdio)         ┌─────────────────────────────┐
│  Your MCP host   │  ───────────────────────▶  │           SEASTAR           │
│ (Claude/Cursor)  │   ask_seastar(question)    │  ┌───────────────────────┐  │
└──────────────────┘  ◀───────────────────────  │  │     agent loop        │  │
                                                 │  │  plan → tool → answer │  │
                                                 │  └──────────┬────────────┘  │
                                                 │             │               │
        ┌────────────────────────────────────────┼─────────────┼───────────────┘
        │                                        │             │
        ▼                                        ▼             ▼
┌────────────────┐                    ┌──────────────────┐  ┌──────────────────┐
│ Local model    │                    │  Obsidian vault  │  │  other MCP       │
│ (any OpenAI-   │                    │  (your notes,    │  │  servers you     │
│  compatible)   │                    │   as memory)     │  │  configure       │
└────────────────┘                    └──────────────────┘  └──────────────────┘
        ▲
        │  everything above this line runs on YOUR machine
   ─────┴───────────────────────── no cloud. no telemetry. ──────────────────────
```

## Project layout

```
src/seastar/
  cli.py         # `seastar init | doctor | serve | ask`
  config.py      # config + runtime/vault autodetection
  inference.py   # runtime-agnostic OpenAI-compatible adapter
  vault.py       # Obsidian vault index, search, read/write, citation
  tools.py       # built-in tools (vault search/read/write/list)
  agent.py       # the agent loop (plan → tool call → answer)
  mcp_server.py  # exposes the agent over MCP
  mcp_client.py  # consumes other MCP servers as tools
```

## Roadmap

- [x] Runtime-agnostic inference adapter
- [x] Vault search / read / write with citations
- [x] Agent loop + MCP server + MCP client
- [ ] Semantic (embedding) recall over the vault
- [ ] `.mcpb` one-click Desktop Extension
- [ ] "Which local models actually work with MCP" conformance table

## The name

There is a dive bar called **The Sea Star** at 2289 3rd Street, in the Dogpatch
neighbourhood of San Francisco. Its sign is an orange octopus holding a martini glass.
Its own words: *"House Octopus overseeing the antics? We've got one of those too!"*

That's the spirit. A sea star has no brain and clings to its rock — SeaStar is the
agent that clings to your notes and never leaves your rock. The octopus is the house
mascot. Fair winds and following seas.

## Contributing

Issues and PRs welcome — especially **conformance reports** ("SeaStar worked with model X on runtime Y").
This project is designed to be *maintained*.

## License

MIT © Roqett / Up Periscope

---

*Built by a winemaker who bought an M4 Pro, got curious, and started a small software factory
called **Up Periscope**. Learned in public.*

*On the advice of Hunter S. Thompson — who said he hated recommending drugs, alcohol,
violence, or insanity to anyone but admitted they'd always worked for him — we took the
parts worth keeping: **no dangerous drugs, only high-quality alcohol, no guns.** Mostly
Python, sometimes Rust, sometimes Swift.*
