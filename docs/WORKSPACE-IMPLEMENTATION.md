# Workspace — what was tried, why it failed, what replaced it

**Status: superseded.** This file used to describe the Workspace panel row as a
finished feature. It was not finished and, more importantly, it should never have
been built. It is kept because a failed experiment that is recorded honestly is
worth more than a row of deleted code with no explanation.

## What was built

A fifth panel row called **Workspace**, showing the agent artefacts found in "the
current directory" — a comma-separated list of paths like
`/Users/lono/Random_MCP/theSeaStar/.trae, .../AGENTS.md`.

Detection looked for eight names: `.trae/`, `.cursor/`, `.opencode/`, `.claude/`,
`.codex/`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`.

## Why it failed

**It was a mirror, not a measurement.** The "current directory" was
`FileManager.default.currentDirectoryPath` — the directory the *app itself* was
launched from. For a menu-bar app that is wherever you happened to be, so the row
described Sea-Star's own boot directory rather than anything in the person's world.
It was not evidence about a harness; it was evidence about the app.

**It was a hardcoded name list again.** Eight names, each of which would have to be
added by hand the day a new tool appeared. This is the trap the foundation exists to
escape — and the same defect found in `KNOWN_HARNESS_COMMANDS`, which is documented
in `DECISIONS.md`. A tool invented tonight would have been invisible to it.

**It was the wrong level.** Vault, Harness, Agent and Inference are all *things you
use*. A workspace is a *property of a harness*, not a fifth thing beside them. Giving
it its own row gave it a weight it had not earned.

**It read as noise.** The founder's verdict: *"still not working as being coherent
and useful, and it's something that critics will go — well what the fuck is that?"*
A path to `AGENTS.md` proves a folder contains a file.

## What replaced it (2026-10-08, founder decision)

**The row is removed. A workspace becomes a property of a harness: where it is
pointed.**

The honest fact is not *which marker files exist in a folder* — it is *where a
running agent is working*. That is:

- read from the process itself (`lsof -a -p <pid> -d cwd`), not from a name list;
- live — it changes when the person changes directory;
- exactly what separates a CLI agent, which has a working directory, from a desktop
  app, which usually has none and then says nothing.

So a harness reads `OpenCode → /Users/lono`, and an app says nothing rather than
inventing a location. Agent *files* found under that directory are evidence about
**that** workspace, attached to the harness working there — not floating as a row of
their own. See `DECISIONS.md` D-022.

The engine-side plumbing this work introduced — passing a workspace path into the
bridge — is **kept**, because the agent roster now uses it: `agents/` directories
beneath the directory a harness is pointed at are the agents that harness can reach
(`candidate_agent_dirs`). The row is gone; the capability is not.