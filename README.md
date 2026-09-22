<div align="center">

# ⭐ SeaStar

**A private, local-first AI agent that lives in your Obsidian vault.**

Goose's power. One-click's ease. Nothing leaves your house.

[![PyPI](https://img.shields.io/badge/pypi-seastar--mcp-blue)](https://pypi.org/project/seastar-mcp/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Python 3.11+](https://img.shields.io/badge/python-3.11%2B-blue.svg)](https://www.python.org/)


<img width="109" height="166" alt="seaStar_SF" src="https://github.com/user-attachments/assets/c2a055c3-cdea-4ecc-a177-45dc0b0184df" />

</div>

---

> A sea star has no brain and clings to its rock.
> SeaStar is the agent that clings to your notes — and never leaves your rock.

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

## Install

```bash
# Zero-install, if you have uv (recommended):
uvx seastar-mcp serve

# Or install it:
pip install seastar-mcp
```

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
      "args": ["seastar-mcp", "serve"]
    }
  }
}
```

Ask your host: *"Ask SeaStar what I decided about the vineyard irrigation project."*
SeaStar searches your vault, reasons locally, and answers **with citations to your own notes**.

## Configuration

SeaStar is zero-config by default: it auto-detects common local runtimes and finds your Obsidian
vault from Obsidian's own config. Override anything in `~/.seastar/config.toml`:

```toml
# ~/.seastar/config.toml
[vault]
path = "~/Documents/MyVault"

[inference]
base_url = "http://localhost:11434/v1"   # any OpenAI-compatible endpoint
model = "qwen2.5:7b-instruct"
api_key = "not-needed-locally"

[mcp_servers.obsidian]
command = "uvx"
args = ["mcp-obsidian", "~/Documents/MyVault"]
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

## Contributing

Issues and PRs welcome — especially **conformance reports** ("SeaStar worked with model X on runtime Y").
This project is designed to be *maintained*.

## License

MIT © Roqett / Up Periscope

---

*Built by a winemaker who bought an M4 Pro, got curious, and started a small software factory
called **Up Periscope**. Learned in public. No drugs, no alcohol, no guns — just Python.*
