# Start Here

*No jargon. If you can install an app and paste a block of text, you can run Sea-Star.*

---

## What Sea-Star is, in one idea

Think of a librarian who has read every note you have ever written, works inside your
house, and never phones a stranger to ask a question.

That librarian is Sea-Star.

You ask it something — *"what did I decide about the irrigation project?"* — and it walks
to the right shelf (your notes), reads the right pages, and answers you **with a pointer
back to the exact note it used.** That pointer is the whole point. It is not a chatbot
guessing. It is your own notes answering, and you can click straight through to check.

Nothing it does leaves your computer. No account. No cloud. No subscription.

## What you need

Just two things, and you may already have both:

| You need | In plain terms | Examples |
| --- | --- | --- |
| **A folder of notes** | Any folder of `.md` files. It does **not** have to be Obsidian — Obsidian just makes it nicer to browse. | `~/Documents/MyVault` |
| **A local model** | An app that runs an AI model on your own machine. | Osaurus, Ollama, LM Studio, oMLX, Unsloth Studio |

> **You do not need Obsidian installed.** A "vault" in Sea-Star is just a folder of
> markdown files. Obsidian is the lovely reading room; the files are the books, and
> Sea-Star only needs the books.

If you have a Mac on macOS 26 or newer, **Osaurus ships a model called `foundation` that
needs zero downloads.** That makes the whole thing a two-piece setup.

## The three moves

You only ever do three things. That's it.

### Move 1 — Start your model

Open your model app and make sure it is running.

- **Osaurus:** run `osaurus serve` in a terminal (or start it from the app).
- **Ollama:** it runs in the background once installed.
- **Unsloth Studio / LM Studio:** press the "start server" button in the app.
- **oMLX:** start the server from the menu bar, or run `omlx serve`.

Sea-Star will *find it by itself* — you don't type any address.

### Move 2 — Tell Sea-Star where your notes are (once)

Open a terminal and run:

```bash
sea-star init --vault "~/Documents/MyVault"
```

Swap in your real folder. This writes one small settings file into that folder and
nothing else. You do this once.

> If you *do* use Obsidian, you can skip this move entirely. Sea-Star reads Obsidian's own
> settings and finds your vault for you.

### Move 3 — Check it, then ask it something

```bash
sea-star doctor
```

If it prints **Ready**, you are done setting up. It should look like this:

```
Vault:    /Users/you/Documents/MyVault
Notes:    128
Runtime:  osaurus -> http://127.0.0.1:1337/v1
Model:    foundation
Available: foundation
Ready.
```

Now ask it a real question — something only *your* notes could answer:

```bash
sea-star ask "What did I write about the irrigation project?"
```

You'll get an answer, and underneath it a line like `Sources: [[Irrigation Project]]`.
That line is a link to the note Sea-Star used. Click it in Obsidian and you're there.

**If you got a cited answer, it works.** That is the entire test.

## What just happened (in one breath)

Sea-Star searched your notes, picked the relevant ones, handed them to your local model,
and asked it to answer *only* from those notes and to name its sources. The model did the
talking; your notes did the knowing; Sea-Star made the introduction. All on your machine.

## Where to go next

- Want your **agent app** (Osaurus, Claude, Cursor, TRAE) to have your memory too?
  → **[Connect it](connect.md)**
- Want to understand every command and setting?
  → **[Reference](reference.md)**
- Something's not working?
  → **[Troubleshooting](troubleshooting.md)**

## Three honest truths

We would rather you trust the docs than be surprised later.

1. **The model is the ceiling.** Sea-Star's plumbing is solid, but answer quality is
   limited by the model you point it at. A tiny model will give a small answer. If
   answers feel thin, use a bigger model.
2. **It is early.** Sea-Star is version 0.1.0. It is small on purpose. Expect rough edges,
   and expect the roadmap to move.
3. **Local means local.** There is no cloud fallback and no telemetry. If you *want* to
   point it at a remote model you can — but you would be doing that by hand, deliberately,
   and you would know.
