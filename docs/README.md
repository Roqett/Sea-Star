# Sea-Star Documentation

Sea-Star is a private, local-first AI agent that uses your Obsidian vault as its memory.
It is an **MCP server that is also an MCP client** — a host app calls `ask_seastar`, and
Sea-Star consumes other MCP servers as its own tools.

This folder explains it at every level, from *"I don't write code"* to *"show me the tool
schemas."* Pick the door that fits where you are right now.

## Pick your door

| If you are… | Read this | What you get |
| --- | --- | --- |
| Not technical, and you want to know *what this actually is* | **[Start here](start-here.md)** | Plain English. No jargon. What it is, what you need, and the three moves to run it. |
| Running it day to day — by clicking, or by typing | **[Use the app](use-the-app.md)** | The menu-bar Cockpit on one side, the exact terminal commands on the other. Two tracks, kept in step. |
| Trying to make it work *with your agent app* | **[Connect it](connect.md)** | The exact steps to wire Sea-Star into Osaurus, Claude Desktop, Cursor or TRAE — plus what to say to the agents. |
| A developer who wants the facts | **[Reference](reference.md)** | Commands, MCP tools, config keys, runtimes, environment variables. |
| A developer who wants to know *how it works* | **[Technical overview](TECHNICAL.md)** | Architecture, the capability ladder, recognition without launching anything, the privacy envelope, the bridge contract, and known debt. |
| Writing the docs, the site, or anything user-facing | **[Brand & style](brand.md)** | The palette and what each colour *means*, type, motion, marks, and the voice rules. |
| Stuck on an error | **[Troubleshooting](troubleshooting.md)** | Every failure we know about, and the fix. |
| A developer, or an agent, changing how Sea-Star behaves | **[Foundation](foundation.md)** | The binding rules — chiefly *"no name is ever a precondition"*, which keeps new harnesses working without new code. |
| An agent picking the work up tomorrow | **[Handover — 2026-10-08](HANDOVER-2026-10-08.md)** | The current state of the world, what changed, what the founder needs to look at, and the traps. **Start here.** |
| An agent from an older session | **[Next session](NEXT-SESSION.md)** | The 2026-10-02 snapshot. Superseded by the handover above, kept for history. |

## The one-paragraph version

You already have notes. You already have a local model. What you don't have is a way for
the model to *read your notes privately and answer with citations*. Sea-Star is that
missing piece. It runs on your machine, finds your vault and your model automatically, and
hands any agent app a single tool — `ask_seastar` — that answers from your own notes.

## The three pieces (know these names)

Almost all confusion about Sea-Star is really confusion about which of three things is
being talked about. They are:

1. **The model** — the "brain" that reads and writes language. Runs locally (Osaurus,
   Ollama, LM Studio, llama.cpp, oMLX, vLLM, Unsloth Studio…).
2. **Sea-Star** — the memory and reasoning layer. It searches your vault, feeds the model
   the right notes, and returns an answer with citations. This is the part you built.
3. **The host** (or *harness*) — the app you actually talk to: Osaurus, Claude Desktop,
   Cursor, TRAE.

Sea-Star sits in the middle. The model and the vault connect to Sea-Star automatically; the
*host* is the one thing you wire up by hand. [Connect it](connect.md) shows exactly how.

## Documentation map

```
docs/
  README.md            ← you are here (index)
  one-pager.md         what it is, for a reader (and a reviewer)
  foundation.md        the binding rules for how Sea-Star must behave
  brand.md             palette, type, motion, marks, voice — for anything user-facing
  TECHNICAL.md         architecture, the capability ladder, privacy, known debt
  start-here.md        zero-jargon explainer + quickstart
  use-the-app.md       the Cockpit (click) and the terminal (type), in step
  connect.md           wire Sea-Star into a host (Osaurus / Claude / Cursor / TRAE)
  reference.md         commands, tools, config, runtimes, env vars
  troubleshooting.md   errors and fixes
  web-canvas-3d.md     the 3D-renderer question, measured rather than argued
  PROGRESS.md          live build state and session handoff (maintainer file)
site/
  index.html           the landing page (static; open it in a browser)
```

The repository's front page ([`README.md`](../README.md)) is the shopfront — what Sea-Star
is and why it exists. This folder is the manual. Neither is the foundation.
