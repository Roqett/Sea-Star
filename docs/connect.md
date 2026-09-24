# Connect It

*How to give your agent app — Osaurus, Claude Desktop, Cursor, TRAE — the memory of your
notes.*

---

## The one thing to understand first

Sea-Star connects in two directions, and only one of them is automatic.

```
                    ┌───────────────────────────────┐
   you wire this    │            HOST               │   ← Osaurus, Claude Desktop,
   up by hand  ───▶ │  (the app you talk to)        │     Cursor, TRAE
                    └───────────────┬───────────────┘
                                    │  MCP (stdio)
                                    ▼
                    ┌───────────────────────────────┐
   automatic  ───▶  │           SEA-STAR            │
   (no config)      │  memory + reasoning layer     │
                    └──────┬─────────────────┬──────┘
                           │                 │
              autodetected │                 │ autodetected
                           ▼                 ▼
                    ┌────────────┐    ┌──────────────┐
                    │ your model │    │ your vault   │
                    └────────────┘    └──────────────┘
```

- **Downward, Sea-Star is automatic.** It finds your model by probing the usual local ports
  and finds your vault from Obsidian's own settings. You configure nothing.
- **Upward, you must introduce Sea-Star to the host.** An MCP host does not magically know a
  server exists. You add one small block of text to the host's settings, and from then on
  **the host launches Sea-Star for you** whenever it needs it.

That block of text *is* the instruction. There is no separate "pairing" step. Add the
block once, restart the host, done.

## The block (this is the whole thing)

This is the same JSON for every host. It says: *"to start Sea-Star, run `uvx` with these
arguments."*

```json
{
  "mcpServers": {
    "sea-star": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/Roqett/Sea-Star",
        "sea-star",
        "serve"
      ]
    }
  }
}
```

- `uvx` runs the tool without you installing it permanently. (It comes with
  [`uv`](https://docs.astral.sh/uv/). If you already ran `sea-star`, you have it.)
- The `args` are just "fetch Sea-Star from GitHub, then run its `serve` command."
- If you cloned the repo locally instead, you can use `"command": "uv"` with
  `"args": ["--directory", "/absolute/path/to/Sea-Star", "run", "sea-star", "serve"]`.

Add that block to whichever host you use, below.

---

## Osaurus

Osaurus is the pairing Sea-Star was designed around: Osaurus is the agent harness, Sea-Star
is the memory.

1. **Start the model.** In a terminal:

   ```bash
   osaurus serve
   ```

   You should see it listening on `http://127.0.0.1:1337`. Leave this running.

2. **Open Osaurus and find the MCP connections screen.** In the app:
   **Settings › Tools › Connections** (older builds may say **MCP Servers**).

3. **Add a server and paste the block** from above. Give it the name `sea-star`.

4. **Save and restart Osaurus** (or toggle the server off and on) so it launches Sea-Star
   and discovers its tools.

5. **Confirm.** Osaurus should now list a tool called `ask_seastar`. If it does, its
   agents can use your vault.

> Menu wording moves between Osaurus versions. The concept never does: *add an MCP server,
> give it the `command`/`args` block.* If you can add an MCP server at all, this works.

## Claude Desktop

Claude Desktop reads a config file. Add Sea-Star to it.

- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

Open that file (create it if it isn't there) and add the `sea-star` entry to
`mcpServers`. If you already have servers, merge — don't replace:

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

Fully quit and reopen Claude Desktop. A small tools icon will appear in the chat box.

## Cursor

Cursor reads `~/.cursor/mcp.json` (and a per-project `.cursor/mcp.json`). The block is
identical:

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

Restart Cursor. Sea-Star's tools appear in the MCP panel.

## TRAE

In TRAE, open the MCP settings panel, choose **Add MCP Server**, and paste the same
`command` / `args` block. TRAE will launch Sea-Star and show `ask_seastar` in its tool list.

## Any other MCP host

If an app speaks MCP, it accepts the same two fields — a `command` and its `args`. That is
the entire contract. There is nothing Sea-Star-specific to learn.

---

## What to say to the agents

Once Sea-Star is connected, the host's agents have a new tool: **`ask_seastar`**. Two ways
to get them to use it.

### 1. Just ask (works immediately)

Say this to any agent in the host:

> **"Ask Sea-Star what I decided about the irrigation project."**

Or:

> **"Use Sea-Star to find my notes on the 2023 Shiraz."**

The agent will call `ask_seastar`, Sea-Star will search your vault and reason locally, and
the answer comes back **with citations to your own notes**.

### 2. Make it automatic (optional, recommended)

If you want the agent to reach for your vault *without being told every time*, put an
instruction in the agent's system prompt or custom instructions:

> You have a tool called `ask_seastar` that answers questions from my private Obsidian
> vault, with citations. When I ask about my own notes, decisions, projects or past work,
> call `ask_seastar` **before** answering from your own knowledge. Prefer its answer and
> keep the `[[wikilinks]]` it returns.

That single paragraph is the difference between "a tool that exists" and "an agent that
remembers."

### The tools the host can see

When Sea-Star connects, it offers these tools:

| Tool | What it does |
| --- | --- |
| `ask_seastar` | The headline. Runs the full local agent loop and returns a cited answer. |
| `vault_search` | Search your notes for a query. Fast, no model round-trip. |
| `vault_read` | Read one note by its path. |
| `vault_list` | List notes, optionally within a folder. |

Full details in the [Reference](reference.md).

---

## Prove it end to end

Do this once, and you'll know the whole chain works:

1. `osaurus serve` — model is up.
2. `sea-star doctor` — prints **Ready**.
3. Connect Sea-Star to your host (above).
4. In the host, ask: *"Ask Sea-Star what my notes say about &lt;something real&gt;."*
5. You get a cited answer, sourced from your own notes.

If step 5 works, model + vault + Sea-Star + host are all connected and talking. That is the
whole system.

Stuck on a step? → **[Troubleshooting](troubleshooting.md)**
