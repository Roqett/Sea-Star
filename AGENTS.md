# Agent Onboarding — Sea-Star

## Who you are working with

An ex-winemaker building a software factory of Mac-first apps (Linux ports planned). He does not code. Agents wrote the specs, the documents and the code — never talk as if he did, and don't assume he has read the file you're changing.

- He doesn't like the terminal much. Run commands yourself.
- Two levels: what he has to decide, and a short technical note with the real names explained as they come up. He wants to learn this over time, but only what matters.
- Context when the work isn't trivial. A small fix doesn't need the whole picture attached.
- One recommendation, not a menu of possibilities. Options are how builds never finish. A single fallback may be offered only after the primary recommendation is rejected.
- Say plainly when he's wrong. Say plainly when you don't know — never paper over uncertainty with confident prose.
- Target hardware is modern Apple Silicon; no weak-hardware compromises. On-device models are the default; any cloud path must be explicit and approved.
- Language-agnostic: the rules below apply regardless of whether the build is Python, Swift, Rust, or anything else. Build commands and package names live in the Project Tripwires.

## Session startup

- **Caffeinate:** If `pgrep caffeinate` returns nothing, run `caffeinate -d -i &`. The screensaver must never interrupt a session.

## Communication protocol

- **No jargon unless asked.** Explain only the impact on the user experience. Define any term you introduce once; skip the definition if already covered.
- **Decision-needed block.** Prefix every pending decision with `Decision needed:` plus a short impact statement, then a single `Recommendation:` line. Stop and wait.
- **Ambiguity safety net.** The founder's words are final. If any instruction is ambiguous, ask before acting — never guess intent on product behaviour.
- **Status brevity.** Updates are 1–2 sentences unless detail is requested.

## Authority — founder-only decisions

Never close, resolve, or implement any of these without the founder's explicit wording:

1. Telemetry & data collection — what is gathered, when, and where it goes.
2. Privacy & security policy — encryption, storage, retention, third parties.
3. Runtime performance-critical changes — launch time, memory, battery, responsiveness of the shipped product.
4. Monetisation & distribution listing — pricing, tiers, trials, package registries, marketplace copy.
5. Scope expansions — any new subsystem, permission, framework, or platform.
6. State-machine or workflow alterations — locked paths, navigation rewrites, onboarding sequence changes.
7. Branding & public-facing copy — project name, tagline, marketing language, README voice.
8. Strategic cutting-edge direction — anything positioning the project as a market first.
9. Cross-app decisions — anything affecting shared code used by other apps in the factory.

## Source of truth

Every project has a single foundation document in `docs/`. Read the sections you are about to touch before any non-trivial change. The onboarding file is a tripwire list, not a substitute for it. Amendments, `DECISIONS.md` (ADRs), and `docs/PROGRESS.md` (live state, parallel-agent file ownership) are also binding.

For Sea-Star the foundation document is [`docs/foundation.md`](docs/foundation.md).

## Locked paths — and how they bend

Locked paths exist to stop silent drift, not to stop deliberate change. Every project separates its constraints into two tiers, declared in the Project Tripwires:

- **Values (Tier 1):** privacy commitments, user-trust rules, safety-critical invariants. These never bend, and any change requires the founder to rewrite the clause himself.
- **Architecture bets (Tier 2):** locked paths, spine types, structural invariants. These are the *current best design*, not eternal truth. They are locked against casual drift, not against a reasoned pivot.

Agents must not modify either tier silently. But a founder-initiated pivot overrides Tier 2 by default — the correct response to "we're pivoting the runtime adapter" is not to recite the spine at him, it is to scope what the pivot breaks and propose the amendment.

Every project declares locked directories after initial creation (see Project Tripwires). Agents may add methods and extensions inside them. They may **not** change type definitions, core logic, or invariant enforcement without explicit approval.

If a feature is genuinely blocked by a locked type, stop and flag it:

> Locked path exception requested: [type], [reason]

Do **not** silently modify locked paths, and do **not** route around them with a parallel unlocked type.

### Pivot protocol

When the founder signals a change of direction ("actually, let's rethink X", "pivot", "scrap that approach"), follow this instead of defending the current design:

1. **Do not argue from the document.** The founder wrote it; he may rewrite it. Reciting invariants back at him is a failure mode, not diligence.
2. **Triage in one short reply:** which Tier 1 values are touched (usually none), which Tier 2 structures break, and what is salvageable.
3. **Recommend one path:** adopt the pivot cleanly via an amendment, or a smaller variant if the breakage cost is genuinely disproportionate. Never simply refuse.
4. **Amend, don't ignore:** if the pivot proceeds, write the amendment document, update the foundation document's clause list, and supersede the affected invariants — the tripwires must reflect the new reality before new work starts.
5. **Distinguish rigidity from correctness.** If the pivot violates a Tier 1 value, say so plainly, once, with the consequence. If he confirms anyway, escalate to the meta-guardrail (he edits the clause) — then proceed.

A locked spine that survives unchanged across a real pivot was probably never tested. Expect the foundation document to be wrong somewhere; treat friction from the founder as the signal that a clause needs amending, not that he needs correcting.

## Memory & context retrieval

- **Query Codebase Memory BEFORE:** structural or multi-file architectural changes, changes touching shared types or locked paths, or implementing existing core protocols.
- **Bypass Memory Query FOR:** direct lint/type-error fixes on files already in active context, isolated leaf-node utility or layout tweaks, and documentation-only or config-only edits.

## Python & Code Quality Invariants

- **Fail Loud on Misconfiguration:** Missing config, an unreachable inference endpoint, or an absent vault must not be hidden behind silent defaults or fallback values. Validate and fail loud during startup or early load.
- **Contract-First Documentation:** Docstrings must describe non-obvious contracts, preconditions, and environment assumptions. Never write comments that merely restate what the code is doing or narrate control flow.
- **Pure Functions & Immutability First:** Prefer pure functions, `@dataclass(frozen=True)`, and `NamedTuple` by default. Mutable state and long-lived objects are reserved strictly for genuine shared mutable state or system lifecycle boundaries.
- **Dependencies over Hand-Rolling:** Prefer well-maintained standard-library modules or established packages (`mcp`, `httpx`, `typer`, `rich`) over custom utility implementations if it genuinely reduces owned code and test burden.
- **Defensive Error Handling:** Never swallow errors silently. Bare `except:` is forbidden. Every handler must log or handle the specific failure context and explain why recovery is safe.

### State & UI Observability

- **State Reconstruction:** Any persistent state change, vault mutation, tool invocation, or agent step must be traceable through structured logging or explicit events. Future agent sessions must be able to inspect state history without guessing.
- **Client UI Copy:** User-facing strings (CLI output, MCP tool descriptions, error messages shown to a person) must stay isolated in a dedicated module rather than hardcoded deep inside logic.

## Execution

### Command whitelist

Run without extra approval: the project's build, test, and git commands as listed in the Project Tripwires. Anything else (system-wide package managers, Docker, etc.) requires explicit founder approval.

### Error handling

On any non-zero exit code: capture the full log, report the error succinctly, and ask the founder how to proceed before retrying.

### Version control

Every change → new feature branch → draft pull request with a concise summary. The founder reviews and merges. Unit tests on every commit; integration tests on nightly CI or on request.

### Parallel agents

File ownership is tracked in `docs/PROGRESS.md`. Read it before starting, claim your files there, and never edit a file another agent owns.

## Definition of done

An item is "done" only when all of these hold:

- Builds and tests pass for every touched package.
- The changelog entry is written (see convention below).
- `docs/PROGRESS.md` is updated to reflect the new state.
- Any decision that was made is recorded in `DECISIONS.md` if it affects architecture, UX flow, or product values.
- The founder has been told, in plain language, what changed and what he now needs to decide (if anything).

## Session handoff

Because different agents and harnesses pick up mid-build, every session must end with a handoff note appended to `docs/PROGRESS.md`: what was completed, what is half-finished and in what state, and the single next step. Never assume the next agent shares your context.

## Changelog entry convention

Every code-changing session appends an entry block to `CHANGELOG.md` in this exact shape:

```
Harness: <IDE / harness name>

Date: <YYYY-MM-DD HH:MM TZ>

Summary of Changes:
- `<file>` — <one-line description of what changed and why>
```

- **Harness and date only.** Both are things the session knows about itself. Do **not** record a model identifier or routing: an agent cannot see the model serving it, so a plausible value is invented rather than observed. Never guess. If the model or routing is wanted for a specific investigation, it comes from `sea-star doctor`, recorded as diagnosed fact rather than self-reported provenance.
- **Harness** = the IDE/host running the session.
- Entries are append-only. Never edit a past entry — if a correction is needed, append a new dated entry that supersedes the earlier one.

## Fallback clause

When a recommendation is rejected:

> Recommendation: X — because [impact].
> If X cannot be adopted, a fallback is Y — a smaller-impact change that still helps.

Only offer the fallback after the founder says the primary recommendation isn't acceptable.

## Hardware profile

`hardware.yaml` is read at runtime and is the only place hardware is specified. If the hardware changes, update this file only.

## Meta-guardrail

Never edit this file unless the founder explicitly asks for a lasting rule. In that case, make only the requested edit — no additional changes.

---

## Project Tripwires (fill in per build)

- **App name & one-line purpose:** Sea-Star — a private, local-first AI agent that lives in your Obsidian vault. It is an MCP server that is also an MCP client: hosts call `ask_seastar`, and Sea-Star consumes other MCP servers (including Obsidian ones) as its own tools.
- **Foundation document:** [`docs/foundation.md`](docs/foundation.md) — binding from 2026-09-28.
  Its lead clause, **"no name is ever a precondition,"** governs all discovery: known names
  are additive hints, never gates on visibility. The repository front page (`README.md`) is
  the shopfront, not the foundation.
- **Language & build commands:** Python 3.11+ managed by `uv`.
  - Install/sync: `uv sync --extra dev`
  - Lint: `uv run ruff check .`
  - Test: `uv run pytest`
  - Run doctor: `uv run sea-star doctor`
  - Run server: `uv run sea-star serve`
- **Architecture style:** Async Python. MCP Python SDK v2 (`MCPServer` — NOT `FastMCP`, which no longer exists in mcp 2.x). Inference is runtime-agnostic: every call goes through one OpenAI-compatible adapter, so Ollama / LM Studio / llama.cpp / MLX / oMLX / vLLM / Unsloth Studio are all just base URLs. Forbidden approaches: hardcoding a single inference vendor; any non-local network egress that the founder has not explicitly configured.
- **Locked paths & tiers:**
  - **Tier 1 (values, never bend):** nothing leaves the machine unless the founder explicitly configured that endpoint and approved it; no telemetry; MIT licence stays.
  - **Tier 2 (architecture bets):** the module boundaries (`config.py`, `inference.py`, `vault.py`, `tools.py`, `agent.py`, `mcp_server.py`, `mcp_client.py`, `cli.py`); the `ask_seastar` tool contract; the `seastar.toml` schema. Adding methods is fine; changing these shapes needs approval.
- **Core invariants:**
  1. **(T1)** All inference is local by default; the only permitted egress is an explicitly configured inference endpoint.
  2. **(T1)** No telemetry, no background monitoring, and nothing written outside the vault and `.seastar/`.
  3. **(T2)** All model calls go through `inference.py`; no other module talks to a model directly.
  4. **(T2)** All vault reads/writes go through `vault.py`; no other module touches the filesystem of a vault directly.
  5. **(T2)** Tool-calling failures fail loud, never silently degrade to a wrong answer.
- **Protocol access rules:** `inference.py` is the only permitted path to a model. `vault.py` is the only permitted path to a vault. The agent loop calls tools; it never reaches into a vault or an endpoint itself.
- **Named exceptions:** none yet.
- **Privacy/product-value clauses:** on-device by default; no cloud fallback unless the founder explicitly configures and approves one; nothing leaves the house quietly.
- **No-go zones (founder rule, 2026-09-26):** The founder's **external drive and any mirror of it** (including its Obsidian vault) are off-limits. No agent or harness may read, index, embed, summarise, quote, or transmit anything from it to a cloud API or third-party model — local-only at most — unless the founder explicitly asks for a specific item in writing. This matches the standing default: don't go there unless asked.
- **Mirrors:** `~/.trae/memory/user_profile.md`, `README.md`, `CHANGELOG.md`.