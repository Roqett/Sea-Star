# Reference

*The facts: commands, tools, configuration, runtimes. For developers and the curious.*

---

## Requirements

- **Python 3.11+**
- **[`uv`](https://docs.astral.sh/uv/)** (recommended) — or plain `pip`
- A **local OpenAI-compatible inference runtime** (see [Runtimes](#runtimes))
- A **folder of markdown files** (an Obsidian vault, or any folder of `.md`)

Tested on macOS (Apple Silicon) with Python 3.11+ and `uv`.

## Install

```bash
# Zero-install, straight from source (recommended):
uvx --from git+https://github.com/Roqett/Sea-Star sea-star serve

# Or clone and work on it:
git clone https://github.com/Roqett/Sea-Star
cd Sea-Star
uv sync --extra dev
uv run sea-star serve
```

`pip install seastar-mcp` arrives with the first PyPI release.

## CLI

| Command | What it does |
| --- | --- |
| `sea-star version` | Print the version. |
| `sea-star init --vault <path>` | Write a `seastar.toml` into a vault and create `.seastar/`. One-time setup. |
| `sea-star doctor` | Check the vault, the runtime and the models. Prints **Ready** when healthy. |
| `sea-star ask "<question>"` | Run one agent query and print the cited answer. |
| `sea-star serve` | Run as an MCP server over stdio. This is what hosts launch. |

`init` options: `--vault/-v <path>`, `--model/-m <name>` (blank = autodetect),
`--base-url <url>` (blank = autodetect).

Commands **fail loud**: a missing vault, an unreachable runtime, or a config error exits
non-zero with a plain-language message — never a silent fallback.

## MCP tools

### What a host sees

Sea-Star presents these four tools to any MCP host:

| Tool | Arguments | Returns |
| --- | --- | --- |
| `ask_seastar` | `question: str` | A cited answer from your vault (runs the full agent loop). |
| `vault_search` | `query: str`, `limit: int = 10` | Matching notes with paths and scores. |
| `vault_read` | `path: str` | The full contents of one note. |
| `vault_list` | `folder: str = ""` | Notes, optionally within a folder, with sizes. |

### What the agent uses internally

Inside the agent loop, Sea-Star also exposes `vault_append` (`path`, `content`) — it can
write back to a note, creating it if needed. It is deliberately **not** handed to the host
as a top-level tool; writing is something the agent does as part of reasoning, not
something a host calls directly.

## Configuration

Sea-Star is **zero-config by default**: it autodetects common local runtimes and finds your
Obsidian vault straight from Obsidian's own `obsidian.json`.

If you want to pin things down, `sea-star init --vault <path>` writes a `seastar.toml`
**into your vault**. Sea-Star also reads `./seastar.toml` from the working directory and
`~/.config/seastar/config.toml`.

**Resolution order** (first match wins): explicit CLI path → `SEASTAR_*` environment
variables → config file → autodetection → a loud failure.

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

| Key | Default | Meaning |
| --- | --- | --- |
| `vault` | autodetected | Path to your folder of notes. |
| `[inference].base_url` | autodetected | OpenAI-compatible endpoint. |
| `[inference].model` | first advertised | Model id. |
| `[inference].api_key` | `seastar-local` | Local runtimes ignore it. |
| `[inference].max_steps` | `8` | Max agent loop steps before failing loud. |
| `[inference].temperature` | `0.2` | Sampling temperature. |
| `[[mcp.servers]]` | none | External MCP servers to consume (see below). |

### Environment variables

Every inference setting can be overridden by environment:

| Variable | Overrides |
| --- | --- |
| `SEASTAR_VAULT` | `vault` |
| `SEASTAR_BASE_URL` | `[inference].base_url` |
| `SEASTAR_MODEL` | `[inference].model` |
| `SEASTAR_API_KEY` | `[inference].api_key` |
| `SEASTAR_RUNTIME` | runtime label (display only) |
| `SEASTAR_MAX_STEPS` | `[inference].max_steps` |

`SEASTAR_VAULT` is handy for testing against a throwaway folder:

```bash
SEASTAR_VAULT=/path/to/demo-vault sea-star ask "what's in here?"
```

### Consuming other MCP servers (MCP client mode)

Sea-Star can borrow tools from other MCP servers and offer them to your model. Each entry
needs a `name` and a `command`; `args` and `env` are optional.

```toml
[[mcp.servers]]
name = "obsidian"
command = "npx"
args = ["-y", "obsidian-mcp", "/Users/you/Documents/MyVault"]

[[mcp.servers]]
name = "myapi"
command = "uvx"
args = ["some-mcp-server"]
env = { API_TOKEN = "..." }
```

Bridged tools are re-exposed under a namespaced name, `<server>__<tool>`, so two servers
can never collide. A server that fails to start raises an error — Sea-Star never pretends a
capability exists when it does not.

## Runtimes

Sea-Star talks to **any OpenAI-compatible endpoint**. It probes these on startup and adopts
the first that answers:

| Runtime | Default endpoint |
| --- | --- |
| Osaurus | `http://localhost:1337/v1` |
| Ollama | `http://localhost:11434/v1` |
| LM Studio | `http://localhost:1234/v1` |
| llama.cpp (`llama-server`) | `http://localhost:8080/v1` |
| MLX (`mlx_lm.server`) | `http://localhost:8080/v1` |
| oMLX | `http://localhost:8000/v1` |
| vLLM | `http://localhost:8000/v1` |
| Unsloth Studio | `http://localhost:8888/v1` |

Runtime-agnostic by contract. Anything that speaks the OpenAI chat-completions protocol
works, even if it is not on this list — set `base_url` by hand.

## Security model

- **Local by default.** The only endpoint Sea-Star talks to is the inference endpoint
  resolved in config, which is local unless *you* set it otherwise.
- **No telemetry, no background monitoring.** Nothing is written outside your vault and
  `.seastar/`.
- **No credentials exposed.** Sea-Star never hands an inference endpoint, a key, or an
  outbound request to a host — it is a front door onto local capability only.
- **Traversal-safe vault access.** All vault reads and writes go through one module and
  cannot escape the vault root.

## Architecture

```
src/sea_star/
  cli.py         # `sea-star init | doctor | ask | serve | version`
  config.py      # config + runtime/vault autodetection
  inference.py   # runtime-agnostic OpenAI-compatible adapter
  vault.py       # Obsidian vault index, search, read/write, citation
  tools.py       # built-in tools (vault search/read/write/list)
  agent.py       # the agent loop (plan → tool call → answer)
  mcp_server.py  # exposes the agent over MCP
  mcp_client.py  # consumes other MCP servers as tools
```

**Core invariants** (see [`AGENTS.md`](../AGENTS.md)):

1. All inference is local by default; the only permitted egress is an explicitly
   configured endpoint.
2. No telemetry; nothing written outside the vault and `.seastar/`.
3. All model calls go through `inference.py` — no other module talks to a model.
4. All vault I/O goes through `vault.py` — no other module touches the filesystem.
5. Tool-calling failures fail loud; they never degrade silently into a wrong answer.

## Development

```bash
uv sync --extra dev          # install with dev tools
uv run ruff check .          # lint
uv run pytest                # tests
uv run sea-star doctor        # smoke check
```

The agent loop is bounded by `max_steps` and raises `AgentError` rather than returning a
half-finished answer. Citations are extracted from the final answer's `[[wikilinks]]`.
