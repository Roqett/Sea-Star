# Sea-Star — what it is, and where it's at

**In one line:** Sea-Star is a private AI assistant that lives inside your own folder of
notes. You ask it something, it reads your notes, and it answers using only those notes,
pointing back to the exact note it used. It runs entirely on your own computer. Nothing is
sent to the cloud.

## What it is

You point it at a folder of markdown notes (an Obsidian vault, or any folder of `.md`
files) and at a local AI model you already have running on your Mac. That is the
setup. Then you ask it things only your notes could answer — "what did I decide about the
irrigation project?" — and it reads the right notes and answers with a link back to its
source.

How that works, and the first test to run, are in [Start here](start-here.md).

## What it does

- **Answers from your notes, with citations.** Every answer names the notes it used.
- **Runs locally.** The thinking happens on your machine, against your model. No cloud, no
  account, no telemetry, no subscription.
- **Works with almost any local model.** Osaurus, Ollama, LM Studio, oMLX, Unsloth Studio
  and more — if the app speaks the common "OpenAI-compatible" API, Sea-Star uses it
  unchanged.
- **Two ways to run the same engine.** A command line that works today, and a Mac app in
  build. Anything you can click, you can also type.
- **Plugs into the agent apps you already use.** It can be added to Osaurus, Claude
  Desktop, Cursor or TRAE so their agents can ask your vault *"what do I already know about
  X?"* — and it can borrow other tools when you want it to.

## Why that's useful

Today you pick two of three: powerful local agents that cost a weekend of configuration;
one-click cloud agents that read your notes; or your vault as the brain, with the wiring
left to you. Sea-Star is the missing third option: a zero-config, fully-local assistant
that treats your vault as its memory and never sends it anywhere.

The idea underneath it: Sea-Star is **shared memory** for your tools. It is the one place
your notes live, so whatever agent you happen to be using can reach them, privately. (It
is not a chat platform, and it does not make separate tools talk to each other; it offers
the same memory to each of them.)

## Where it's got to

- **The engine is finished and tested** — 51 automated tests passing. It can connect to a
  vault, search and read it, answer with citations, run as a tool for other apps, and
  borrow other apps' tools in turn.
- **The Mac app is built and running** — a menu-bar "Cockpit" with two ways to read your
  world: a **List** and a **Graph**. The graph draws your vault, your local model engines,
  and your models as glowing sea-stars. From the app you can start and stop the engine,
  watch its logs, open Settings, and check for updates.
- **It works end to end** on the developer's machine: the app starts the engine, the engine
  answers, and the answer cites real notes.

## What is not done yet

- It is **version 0.1.0 and unreleased**; the repository is still private.
- Semantic search, a one-click installer, and a Linux port are on the roadmap, not in hand.
- The macOS app is not yet notarised for general distribution.

## Where it is heading (not built yet)

The next idea is to put your **agents**, not only your models, on that graph, each shown
with the model it is bound to, so you can see which agents are running and what each one is
pointed at.

## The question for the reviewer

Is this a private, local, citation-first assistant for your own notes clear and useful
enough to publish, or does it still read as one of many? Name the strongest reason to use
it, and the weakest.
