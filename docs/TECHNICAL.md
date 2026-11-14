# Sea-Star — technical overview

For the technically minded. If you want the plain-English version, read
[one-pager.md](one-pager.md) instead. If you want to *operate* it, read
[reference.md](reference.md).

This document describes how the system is actually built, and — as importantly —
how it decides what it is allowed to claim. That second part is the unusual part of
this codebase, so it gets the most space.

---

## 1. What the thing is

Two pieces, one contract between them.

```
┌──────────────────────┐   MCP (stdio)    ┌──────────────────────────────┐
│   Your MCP host      │ ───────────────▶ │         SEA-STAR            │
│ Claude/Cursor/TRAE   │  ask_seastar(q) │  agent loop (bounded)       │
│ Osaurus/OpenCode     │ ◀─────────────── │  ├─ vault tools              │
└──────────────────────┘   answer+citations│  └─ bridged MCP tools       │
                                            └──────┬───────────┬──────────┘
                                     OpenAI /v1    │           │  filesystem
                    ┌───────────────────────────────┘           │
                    ▼                                           ▼
        ┌───────────────────────┐                  ┌──────────────────────┐
        │ Local model endpoint  │                  │  Obsidian vault      │
        │ (any OpenAI-compatible│                  │  (.md files)         │
        │  server, on loopback) │                  └──────────────────────┘
        └───────────────────────┘
```

**A native macOS app** (`macapp/`) sits on top as a menu-bar cockpit. It does not
contain the engine — it shells out to the CLI and decodes `sea-star doctor --json`.
Everything the app can do, the command line can also do.

### The engine (`src/sea_star/`)

| Module | Responsibility |
| --- | --- |
| `config.py` | Config resolution, vault detection, **runtime probing**. The only module that speaks HTTP to a model. |
| `inference.py` | The one path to a model. OpenAI-compatible, over raw `httpx`. |
| `vault.py` | The only module that touches vault files. |
| `agents.py` | Reads agent rosters (Osaurus today). |
| `recon.py` | **Reconnaissance.** One-shot, stateless reads of this machine's own process and socket tables. |
| `harnesses.py` | Harness discovery and the rung each one reached. |
| `connections.py` | Records which process spawned `serve` — stdio attachment is invisible to a port probe. |
| `providers.py` | Reads what a harness *declares* it uses. |
| `register.py` | The ask-once store at `~/.seastar/register.json`. |
| `tools.py` | Tool registry + built-in vault tools. |
| `agent.py` | Bounded loop: plan → tool → answer. Fails loud. |
| `mcp_server.py` | Exposes `ask_seastar`, `vault_*`, `machine_report`. |
| `mcp_client.py` | Consumes other MCP servers as its own tools. |

### The app (`macapp/`)

XcodeGen + AppKit-hosted SwiftUI (`SeaStarMain` → `AppDelegate` → `NSStatusItem` +
`NSPopover`). `App/`, `Views/`, `Models/`, `Services/`, `Support/`, `Shaders/`.

**`EntityGraphModel` is the single source of truth for the graph.** Two renderers read
it — the flat 2D pool (`EntityGraphView`) and the 3D room (`GraphSceneView`) — so they
cannot disagree about what is true. It is a pure value type: given a report, it
produces nodes and edges. No I/O, no clock, no view state.

---

## 2. The part that is unusual: the capability ladder

Most tools in this space decide *which product* something is and branch on the name.
Sea-Star never asks that. It asks **"what can this thing prove?"**, in a fixed order,
stopping at the first yes.

| Rung | Establishes | Obtained by | Needs a name? |
| --- | --- | --- | --- |
| 0 | **Declared** — someone told us | `seastar.toml`, `SEASTAR_*` env | No |
| 1 | **Present** — an app exists on disk | `Info.plist` in the Applications folders | No |
| 2 | **Running** — a process exists | Process inspection | No |
| 3 | **Listening** — something answers in the OpenAI shape | Port sweep + `/v1/models` | No |
| 4 | **Self-describing** — it named itself or listed models | `owned_by`, model list | No |
| 5 | **Agent-aware** — it can name its configured agents | Adapter, or MCP probe | Usually |
| 6 | **Activity-aware** — it can report in-flight requests | Adapter | Yes |
| 7 | **Caller-attributed** — we know which agent made *this* request | Instrumentation both sides | Yes |

Rungs 0–4 are vendor-neutral and must stay that way. That is why Sea-Star works with
a runtime released last month. Rungs 5–7 are where adapters earn their keep.

### The degradation contract

> **Show the highest rung reached, and show the rung.**

`Configured`, `Reachable`, `Active`, `Unavailable` and `Last reported` are different
facts and may never be collapsed. A configured route is not a running model. A loaded
model is not an active request. A healthy endpoint does not prove anyone is using it,
and never names the caller.

This is not aspirational — it is enforced in tests. `EntityGraphTests.swift` pins that
`isLive` is true for exactly the observed set, that a harness with no answering port
is never live under any circumstance, and that a declaration in a config file never
makes a node live.

### The consequence in the UI

The rung is a *drawing* concern, not just a label:

- A **connected** harness is lit and **breathes**.
- A **running but unattached** harness (D-020) takes a **steady** glow — visibly alive,
  with none of the breath, because "up" and "carrying work" are different facts.
- A **present but dormant** install is dark.

Before D-020 the draw function gave every non-live node `glow = 0`, which rendered a
running IDE pixel-identical to an app that never launched. The engine had correctly
told the rungs apart; the drawing threw the distinction away.

---

## 3. No name is ever a precondition

The governing clause. Every known name in the codebase is a *hint* that improves a
label, and **its absence may never reduce what is displayed**.

The test for any name-keyed behaviour: *if this name vanished from the registry
tomorrow, does the product get worse — we lose a label, a nicer icon — or blank, the
thing disappears?* If it goes blank, the behaviour is a gate and violates the clause.
The fix is never "add more names." The fix is a degraded path for the unknown case.

How that is actually implemented:

- **Discovery is by vocabulary, not by list.** A ~20-word vocabulary of protocol terms
  (`mcpServers`, `modelcontextprotocol`, provider names, model words) finds harnesses
  that did not exist when the table was written. The reasoning is recorded: the first
  implementation searched for *provider* words (`anthropic`, `openai`) and missed CC
  Switch until the search used *agent* words (`claude`, `codex`, `gemini`).
- **Roles bar things out instead of names.** A browser is excluded by **declared role**
  — it claims `http`/`https` in its own `Info.plist` — and an OS component by living
  under `/System/`. Not a list of products. This cut 17 candidates to 13, all genuine,
  with zero false positives.
- **Unrecognised apps degrade, they don't vanish.** `KNOWN_HARNESS_APPS` is a seed
  table and a first-run hint. `register.py` asks once per unknown thing and remembers
  the answer by **bundle id or path, never by display name**.

### The errors this has caught

Three category errors of the same shape, all now pinned by tests:

| Error | What happened |
| --- | --- |
| **A name as a gate** | An app outside the allowlist was skipped entirely rather than shown degraded. |
| **A port is not a server** (D-010) | The ledger claimed *"Unsloth serves models on 8888"* — that port had never been probed. Now `serves` (proved) and `listening` (suspected) are separate fields. |
| **A URL is not a model route** (D-021) | The provider reader reported `https://mcp.exa.ai/mcp` as OpenCode's model provider, because it accepted any URL. |

---

## 4. Recognition without launching anything

`recon.py` reads this machine's own process and socket tables — the same ones Activity
Monitor reads — and attributes every listening port and outbound connection to the
`.app` that owns the process tree.

- **Triggered, never watching.** No timer, no thread, nothing kept between calls.
- **No permission required.** `lsof` needs no sudo and no system extension.
- **Never opens a connection.** `recon` must not answer a question about connections
  by making one; the caller threads in which ports actually answered.

What it found on the developer machine that nothing could see before: four loopback
model servers, each attributed to its owning app — including **one of them being
Sea-Star's own brain**, inside another app. Quitting that app stops Sea-Star thinking,
and the app now says so.

### The behaviour ledger

One row per app: what it serves, whether it uses its own server, what it reaches for
outside, and the flagged case (ships a server, doesn't use it, reaches outside anyway).

Three rules keep it trustworthy:

1. **No motive is attributed.** There is no field for intent.
2. **"Not using them" is never said.** Sea-Star itself may be the client.
3. **A stranger is a candidate, not a ledger row.** The first version listed Chrome
   beside oMLX.

---

## 5. Symmetry: what we can prove must be callable

If a fact is only ever visible on screen, a harness cannot see it — and the cockpit's
entire value is that it knows things the harnesses do not. Anything Sea-Star claims
about the machine should be reachable **over MCP as a tool**, not only drawable in the
app.

Hence `machine_report`, which exposes the machine survey, the harness roster and the
cascade's placements to any attached host.

### Where MCP cannot help

**MCP cannot discover inference.** It has no schema for "which model servers do I
run"; its handshake identifies who is attached, and its tools expose what that server
chooses to offer. Inventing a tool for it would mean every harness implementing it —
the app-name-list trap one layer up.

The OpenAI-compatible `/v1/models` is the protocol that exists for this, and Sea-Star
already speaks it. The asymmetry is the honest finding, not a gap.

---

## 6. Privacy as an architectural constraint

- **Nothing leaves the machine** unless the founder explicitly configured that endpoint
  and approved it.
- **No telemetry, no background monitoring**, nothing written outside the vault and
  `.seastar/`.
- **Never stored by default:** prompts, model outputs, tool arguments or results,
  private agent prompts, config exports, secrets, note contents.
- Activity records would carry *who*, *what route*, *when* and *how we know* — never
  *what was said*.

### Derived fields only

Two modules read things they must not retain, and both are structured so the raw
material cannot leak into a result:

- `connections.py` stores derived identity (name, bundle id, app path) and **never raw
  `ps` command lines** — those can contain shell exports and tokens.
- `providers.py` returns `(provider, base_url, model)` in a frozen dataclass. API keys
  and the raw document never enter it. A test asserts a config full of `apiKey`,
  `authToken` and `password` yields a claim containing none of them.

Both readers also fail *tolerantly*: an unreadable or malformed file degrades to absent
rather than failing the read. The foundation's rule is that a missing name never
removes what is displayed.

---

## 7. Testing strategy

**179 Python tests, 102 Swift tests in 18 suites**, both green.

The load-bearing idea is that the *honesty* rules are pinned as tests, not comments. A
rule that lives only in a doc comment will be broken by the next plausible-looking
refactor.

Notable patterns:

- **Fixtures are decoded JSON, not constructed objects.** They are shaped like what
  `doctor --json` actually emits, so the tests fail if the **contract** drifts, not
  only if the graph does.
- **The negative cases carry the weight.** For the provider reader: malformed JSON
  degrades, an unlisted harness is unread rather than invisible, a claim never borrows
  a neighbour's, an MCP URL is never a model route.
- **An autouse fixture keeps the doctor tests off the real machine.** Without it they
  began reading the live socket table and went from 0.4s to 7.2s.
- **Swift tests build a `ServerController` with `command: nil`**, so nothing spawns and
  nothing is probed; `ready` is whatever the fixture says.

---

## 8. Failure modes, and what happens instead

| Failure | Behaviour |
| --- | --- |
| No vault found | **Fails loud.** Names the paths it looked at. Never silently creates one. |
| No local endpoint answers | Reports every port it swept. Never falls back to a cloud model. |
| Endpoint answers no model list | Reports the endpoint as present-but-unnamed, not as ready. |
| A model is offered but not loaded | Says "on offer", not "running". oMLX's admin API is the one runtime that can be *asked*. |
| Bridge JSON decode fails | One plain-language message, never a crash, never a blank row. |
| Unknown MCP server config | Reported as presence only. Never the tool names inside another app's config. |
| `serve` sees stdin EOF | Exits immediately — it is a stdio server. The app holds a `Pipe` open so it stays alive, and a `terminationHandler` distinguishes *stopped by request* from *exited on its own*. |

That last row is worth remembering: `isServerRunning` was once reporting `true` while
nothing was serving, because the child inherited the app's closed stdin, saw EOF and
exited in the same breath.

---

## 9. Known debt

Logged honestly rather than rediscovered. From `docs/foundation.md` §6 and the
decision record:

1. **`harnesses.py` gates on a bundle-id allowlist.** Logged as a §1 violation since
   2026-09-28 and still open. It is the clearest gap between what the document promises
   and what the code keeps.
2. **No MCP-based activity probe.** Rung 5 by protocol is unavailable.
3. **Telemetry vs Tier 1.** Foundation §4 keeps "no telemetry, no background
   monitoring"; the ledger is live-only, not historical. A ledger *with memory* is a
   values question and therefore the founder's.
4. **Rung 7 has no instrumentation.** Per-agent, per-request attribution is the
   largest open question in the product.
5. **The engine is not bundled inside the app.** A DMG containing only the menu-bar app
   would find no engine on a stranger's Mac. No amount of signing fixes it.
6. **`RuntimeProbe.model` is still `models[0]`** for any runtime without a loaded-model
   flag. That is a guess, and the honest fix is to describe such an endpoint as
   *offering* rather than *answering as* — which reaches the bridge contract and the
   panel's wording.

---

## 10. The bridge contract

`sea-star doctor --json` — always exactly one JSON object, even on failure.

```jsonc
{
  "schema_version": 1,
  "ready": true,
  "vault":    { "path": "…", "source": "obsidian", "note_count": 128, "candidates": [] },
  "runtimes": [ { "name": "omlx", "base_url": "…", "model": "…", "models": [] } ],
  "latent_harnesses": [ { "name": "…", "bundle_id": "…", "path": "…", "rung": "running" } ],
  "mcp_clients":     [ { "name": "…", "bundle_id": "…", "pid": 0, "started_at": "…" } ],
  "providers":       [ { "harness": "…", "provider": "…", "base_url": null,
                         "model": "…", "evidence": "configured", "local": true } ],
  "listening": [], "model_like": [], "behaviour": [], "candidates": [],
  "server": { "state": "…" }
}
```

**Every addition has been additive**, `schema_version` has stayed `1`, and a key's
absence is read as *"this build did not look"* — never as a claim about the machine.
An older engine yields `[]` and the app shows nothing rather than inventing a picture.

**One field is known-stale:** `server.state` is derived from whether the *inference
endpoint* answered, not from whether the MCP server is running. The app ignores it and
tracks real process state itself. It is kept alive by its own test and seven Swift
fixtures; nothing reads it for truth. It is a name that outlived the thing it named.

---

## 11. Reading order

| If you want | Read |
| --- | --- |
| The rules the code must keep | [`docs/foundation.md`](foundation.md) |
| Why a decision was made | [`DECISIONS.md`](../DECISIONS.md) — D-001…D-021, append-only |
| Every command, tool and setting | [`docs/reference.md`](reference.md) |
| What is being built next, and why | [`docs/PROGRESS.md`](PROGRESS.md) — the newest handoff is last |
| The 3D canvas question, measured | [`docs/web-canvas-3d.md`](web-canvas-3d.md) |
