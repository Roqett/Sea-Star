# Start Here

## What Sea-Star is

Sea-Star gives your AI agent a memory made of your Obsidian notes. You keep months of work in a vault; a chatbot or agent knows none of it and forgets everything between sessions. Install Sea-Star and any agent, in your harness, Claude Desktop or Cursor, can ask "what do I already know about X?" and get an answer from your notes, with citations you can click. It runs entirely on your machine. Use it when your notes are the thing your agent is missing.

Think of a librarian who has read every note you have ever written, works inside your house, and never phones a stranger. That librarian is Sea-Star.

## What it replaces

A local harness gives you power and asks for a weekend of configuration. A one-click cloud agent is easy and reads your notes on someone else's machine. Sea-Star makes the vault you already have the memory: it searches your notes, hands the relevant ones to a local model, and returns an answer linked to the note it used.

## When to reach for it

- You keep re-deciding things you already wrote down.
- You want an answer you can check against the source.
- Your notes cannot leave the machine.

## What you need

| You need | In plain terms | Examples |
| --- | --- | --- |
| **A folder of notes** | Any folder of `.md` files. Obsidian is optional. | `~/Documents/MyVault` |
| **A local model** | An app that runs an AI model on your own machine. | Osaurus, Ollama, LM Studio, oMLX, Unsloth Studio |

If you have a Mac on macOS 26 or newer, Osaurus ships a model called `foundation` that needs no download, so this becomes a two-piece setup.

## The first test

1. **Start your model.** Run `osaurus serve`, or start the server in Ollama, LM Studio, oMLX or Unsloth Studio. Sea-Star finds it.
2. **Point Sea-Star at your notes.** Once:
   ```bash
   sea-star init --vault "~/Documents/MyVault"
   ```
   If you use Obsidian, you can skip this: Sea-Star reads Obsidian's own settings.
3. **Check the setup.**
   ```bash
   sea-star doctor
   ```
   **Ready** means the vault and a model are both in reach.
4. **Ask something only your notes know.**
   ```bash
   sea-star ask "What did I write about the irrigation project?"
   ```
   A cited answer is the test: `Sources: [[Irrigation Project]]` links to the note used.

## Three honest truths

- **The model is the ceiling.** Sea-Star's plumbing is solid, but answer quality follows the model you point it at.
- **It is early.** Version 0.1.0, small on purpose; expect rough edges and a moving roadmap.
- **Local means local.** No cloud fallback, no telemetry. You can point it at a remote model by hand, deliberately.

## Where to go next

- Your agent app should have the memory too → [Connect it](connect.md)
- Every command and setting → [Reference](reference.md)
- Something broken → [Troubleshooting](troubleshooting.md)
