<div align="center">

<img src="assets/sea-star.png" alt="The Sea Star — the octopus with the martini glass" width="300">

# ⭐ Sea-Star

**A private, local-first AI agent  with a MacOS menubar cockpit that lives in your Obsidian vault.**
One-click's ease. Nothing leaves your house.

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Python 3.11+](https://img.shields.io/badge/python-3.11%2B-blue.svg)](https://www.python.org/)

</div>

***


> — The Sea Star, 20th n 3rd, Dogpatch, SF, Ca,  USA
> This cute snack also thanks Tom's drydock around the corner. As it was.

A sea star holds on tight to its rock and doesn't let go.
Sea-Star does the same with your notes — and helps you find the right one.

***

## Documentation

Four pages, one for wherever you're starting from. Start at the
**[docs index](docs/README.md)** if you're unsure.

| I want to…                                                   | Read                                               |
| ------------------------------------------------------------ | -------------------------------------------------- |
| Understand what this is, in plain English (no jargon)        | [docs/start-here.md](docs/start-here.md)           |
| Connect Sea-Star to Osaurus / Claude Desktop / Cursor / TRAE | [docs/connect.md](docs/connect.md)                 |
| See every command, tool, setting and runtime                 | [docs/reference.md](docs/reference.md)             |
| Fix something that's broken                                  | [docs/troubleshooting.md](docs/troubleshooting.md) |

***

## The problem

Right now you get to pick two of three:

- **Powerful local Harnesses** (Opencode, Buzz, custom stacks) — but configuring them is a weekend of YAML and silent failures.

- **One-click agents** (the frontier products) — but they're cloud, proprietary, and they read your notes.

- **Your Obsidian vault as the brain** — but wiring Obsidian + a local model + an agent loop together is left as an exercise for the reader.

**Sea-Star is an AI Cockpit and the missing third option:** the zero-config, fully-local agent that treats your Obsidian vault as first-class memory, runs on whatever local model you already have, and plugs into whatever MCP host you already use.

## What it is

Sea-Star is an **MCP server that is also an MCP client**. That sounds odd, but it's deliberate:

- As an **MCP server**, it exposes one simple tool (`ask_seastar`) to any host — Claude Desktop, Cursor, TRAE, whatever. That tool runs a full local agent loop.

- As an **MCP client**, it *consumes* other MCP servers — including the existing Obsidian ones — as its own tools.

The reasoning happens on **your** machine, against **your** model. The host is just a window.

## Why it stays sovereign

Sea-Star talks to any **OpenAI-compatible** local inference endpoint. That means it works, unchanged, with:

| Runtime                    | Default endpoint            |
| -------------------------- | --------------------------- |
| Osaurus                    | `http://localhost:1337/v1`  |
| Ollama                     | `http://localhost:11434/v1` |
| LM Studio                  | `http://localhost:1234/v1`  |
| llama.cpp (`llama-server`) | `http://localhost:8080/v1`  |
| MLX (`mlx_lm.server`)      | `http://localhost:8080/v1`  |
| oMLX                       | `http://localhost:8000/v1`  |
| vLLM                       | `http://localhost:8000/v1`  |
| Unsloth Studio             | `http://localhost:8888/v1`  |

Runtime-agnostic by contract. You never touch this layer again.

## The focused setup: Osaurus + Unsloth Studio
I built Sea-star after thinking it would be cool for an Osaurus (my fave harness that week ) agent.. just to hop over to Unsloth studio and do some fine tuning
It is runtime-agnostic on purpose — but if you want the *specific* pairing that
inspired it, this is the one: **Osaurus for the agent layer, Unsloth Studio for the
model-and-skills layer, Sea-Star for the memory.**

The two are complementary by nature. Osaurus is a Mac-native agent harness — it runs
agents, loads skills, and speaks MCP both ways. Unsloth Studio is a model workbench —
it runs and fine-tunes models and exposes an **OpenAI-compatible API**. Osaurus brings
the *doing*; Unsloth brings the *thinking*; neither one knows about your notes. Sea-Star
is the third leg: it gives them a shared, private memory in your Obsidian vault.

```
┌────────────────────┐   MCP    ┌──────────────┐   OpenAI-compatible   ┌──────────────────┐
│  Osaurus (agents)  │ ───────▶ │   Sea-Star   │ ────────────────────▶ │ Unsloth Studio   │
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
2. **Point Sea-Star at it.** Put that URL and the model name in your `seastar.toml`
   under `[inference]` — see Configuration below. That's the whole "Unsloth is the brain" step.
3. **Point Osaurus at Sea-Star.** Add Sea-Star as an MCP server in Osaurus (the same
   `command` / `args` block you'd add to Claude Desktop). Osaurus now has your vault
   as memory; its agents can ask Sea-Star what you already know.

> Menu labels drift between versions of both apps — the *concept* is what matters:
> Unsloth serves an OpenAI-compatible endpoint, Sea-Star consumes it, Osaurus calls Sea-Star.
> If either app exposes a compatible endpoint, this works unchanged.

And if you'd rather use a different harness tomorrow — Buzz, Opencode
Desktop, Deepseek Harness MacOS (omarchy soon .. ) — **nothing above changes.** That flexibility is the point.

> **Zero-download shortcut (macOS 26+).** Osaurus ships AFM. Run `osaurus serve`, and you can skip Unsloth entirely: Sea-Star
> autodetects Osaurus on `http://127.0.0.1:1337/v1` and uses `foundation` as the brain.
> Two legs instead of three, and nothing to download.

## Install

```bash
# Zero-install from source, if you have uv (recommended):
uvx --from git+https://github.com/Roqett/Sea-Star sea-star serve

# Or clone and run it locally:
git clone https://github.com/Roqett/Sea-Star
cd Sea-Star
uv sync
uv run sea-star serve
```

> `pip install seastar-mcp` lands with the first PyPI release. Until then, the
> `uvx --from git+...` form above is the one-liner to use.

## Quickstart

```bash
# 1. Point Sea-Star at your Obsidian vault
sea-star init --vault "~/Documents/MyVault"

# 2. Check that it can see a local model
sea-star doctor

# 3. Run it as an MCP server (stdio)
sea-star serve
```

Then add it to your MCP host of choice:

```json
{
  "mcpServers": {
    "sea-star": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/Roqett/Sea-Star", "sea-star", "serve"]
    }
  }
}
```

Ask your host: *"Ask Sea-Star what I decided about the vineyard irrigation project."*
Sea-Star searches your vault, reasons locally, and answers **with citations to your own notes**.

## How you use it

Sea-Star has three ways to use it. Use any one on its own; they compose.

### Way 1 — Ask your folder of notes from the terminal (the fastest way to *feel* it)

No host, no config file, no JSON. If a local model is running, this works:

```bash
sea-star ask "What did I decide about the vineyard irrigation project?"
```

Sea-Star searches your vault, reads the matching notes, asks your local model, and
prints the answer with `[[wikilinks]]` back to the notes it used:

```
The Grenache bottling run is booked for the second week of February, and you should
order more corks before the McLaren Vale crush starts.

Sources: [[Cellar Notes]]
```

That citation is the whole point. It isn't a chatbot guessing — it's your notes
answering, and you can click straight through to the source.

### The 60-second smoke test

```bash
# 1. Is a vault and a model in reach?
sea-star doctor
```

```
Vault:    /Users/you/Documents/MyVault
Notes:    128
Runtime:  osaurus -> http://127.0.0.1:1337/v1
Model:    foundation
Available: foundation
Bridged MCP servers: none
Ready.
```

If it says **Ready**, you're done. If it says `No local inference server answered`,
start your runtime (see the recipe above) or point Sea-Star at one in `seastar.toml`.

```bash
# 2. Ask something only your notes know
sea-star ask "Summarise what I wrote about <a real thing in your vault>"
```

If step 2 returns a cited answer, the vault, the model, and the agent loop are all
proven. That's the test.

### Way 2 — Put Sea-Star behind your agent harness (MCP server)

This is the "Osaurus gets your memory" move. Register Sea-Star as an MCP server:

```json
{
  "mcpServers": {
    "sea-star": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/Roqett/Sea-Star", "sea-star", "serve"]
    }
  }
}
```

- **Osaurus** — Settings › Tools › Connections › add the block above. Osaurus then
  exposes one tool, `ask_seastar`, to its agents.

- **Opencode Desktop / Cursor / TRAE work** — the same block, in the app's `mcpServers` config.

Now any agent in the host can ask *"what do I already know about X?"* and get your
vault's answer, locally.

> The full walkthrough — exact menu paths, config file locations, and the instruction to
> give the host's agents — lives in **[docs/connect.md](docs/connect.md)**.

### Way 3 — Let Sea-Star borrow other MCP servers (MCP client)

Sea-Star can consume other MCP servers and offer their tools to your model. In
`seastar.toml`:

```toml
[[mcp.servers]]
name = "obsidian"
command = "npx"
args = ["-y", "obsidian-mcp", "/Users/you/Documents/MyVault"]
```

Restart, and Sea-Star's agent loop can call `obsidian__*` tools alongside its own vault
tools. That's how you give the agent more to work with.

### Which do I start with?

Start with **Way 1** (`sea-star ask`) — it's the honest test. Then wire **Way 2** into
Osaurus, and add **Way 3** only when you want a second tool source.

## Configuration

Sea-Star is zero-config by default: it auto-detects common local runtimes **and**
finds your Obsidian vault straight from Obsidian's own `obsidian.json`, so for most
people `sea-star serve` just works with no setup at all.

If you want to pin things down, `sea-star init --vault <path>` writes a `seastar.toml`
**into your vault**. Sea-Star also reads `./seastar.toml` from the working directory and
`~/.config/seastar/config.toml`. Resolution order is: explicit path → `SEASTAR_*`
environment variables → config file → autodetection → a loud failure.

```toml
# <your-vault>/seastar.toml
vault = "/Users/you/Documents/MyVault"

[inference]
# Leave base_url empty to let Sea-Star autodetect a local runtime on startup.
base_url = "http://127.0.0.1:11434/v1"   # any OpenAI-compatible endpoint
model = "qwen2.5:7b-instruct"
api_key = "seastar-local"                # local runtimes ignore this
max_steps = 8
temperature = 0.2

# Consume other MCP servers (e.g. an Obsidian MCP) as Sea-Star's own tools.
[[mcp.servers]]
name = "obsidian"
command = "npx"
args = ["-y", "obsidian-mcp", "/Users/you/Documents/MyVault"]
```

> **Heads up:** a `seastar.toml` can hold a real `api_key`. If your vault is under
> version control or cloud sync, add `seastar.toml` to your `.gitignore` so it doesn't
> get committed or shared.

## How it works

```
┌──────────────────┐        MCP (stdio)         ┌─────────────────────────────┐
│  Your MCP host   │  ───────────────────────▶  │           SEA-STAR          │
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
src/sea_star/
  cli.py         # `sea-star init | doctor | serve | ask`
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

There's a bar called **The Sea Star** at 20th n 3rd, in the Dogpatch
district of San Francisco. I stone's throw from the birthplace of GPT some 30 years later. The Builder spent some time there ( with a qwirky Grey timberwolf)..a long time ago.
The Sea-stars in South Australia 's Spencer Gulf are just as colourful and EVERY single one : TOTALLY unique 

That's the spirit. A sea star holds on tight to its rock and doesn't let go. Those arms (or legs ) are independent, but connected :  Sea-Star
does the same with your notes and lets you know the big picture.

## Contributing

Issues and PRs welcome — especially **conformance reports** ("Sea-Star worked with model X on runtime Y").
This project is designed to be *maintained*.

## License

MIT © Roqett / Up Periscope

***

*Built by an Oz winemaker who as a lad bought a Sinclair Spectrum 16K (but only got as far as trying to copy "blue Monday ' in BASIC )..timewarp to pulling the pin after vintage 2025, upgraded to a M4pro Mini 64GB, and relearnt to build. an Indy-dev build is a lot like a mini vintage. 
 Learnt in public.*

*On the advice of the late Hunter S. Thompson — who said he hated recommending drugs, alcohol,
or insanity to anyone... but admitted they'd always worked for him — we took the
parts worth keeping:* ***no dangerous drugs, only high-quality alcohol, no propellant weapons.*** *Mostly
Swift, Python, sometimes Rust, mainly Swift.*
