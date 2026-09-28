# Sea-Star — Foundation

The binding document. Read this before any non-trivial change.

`AGENTS.md` is the tripwire list and the onboarding contract; it points here. This file
holds the decisions that are expensive to reverse and cheap to state.

**Status of this file:** the founder commissioned it on 2026-09-28 and it is binding from
that date. The clauses marked **Tier 1** are values — see *Tiers* below.

---

## 1. The one principle

> **No name is ever a precondition.**
>
> Every known name in Sea-Star is a *hint* that improves a label. Its absence may never
> reduce what is displayed.

This single clause governs harness discovery, runtime discovery, agent rosters, model
attribution, and every future integration. It exists because the first build of Sea-Star
learned this the expensive way: an app whose bundle id was absent from a hardcoded list
was not shown with less detail, it was not shown at all. The screen looked empty. That is
the failure this document exists to prevent.

**Concretely, a registry of known harnesses is additive, never subtractive.** Shipping a
list of the ten most popular harnesses is good work. It is *upgrades*, not *permission*.
When the list is stale, incomplete, or a year out of date, the product must be no worse
off than it was before the list existed.

### The test

Before shipping any name-keyed behaviour, ask:

1. If this name vanished from the registry tomorrow, does the product get **worse** (we
   lose a label, a nicer icon, a helpful hint) or **blank** (the thing disappears)?
2. If it goes blank, the behaviour is a gate and violates this clause.
3. The fix is never "add more names." The fix is a **degraded path** for the unknown case.

---

## 2. The capability ladder

Sea-Star never asks *"which harness is this?"* It asks *"what can this thing prove?"* —
the same questions of everything, in a fixed order, stopping at the first yes.

| Rung | What it establishes | How it is obtained | Needs a name? |
| --- | --- | --- | --- |
| 0 | **Declared** — someone told us about it | `seastar.toml`, `SEASTAR_*` env | No |
| 1 | **Present** — an app exists on disk | `Info.plist` in the Applications folders | No |
| 2 | **Running** — a process exists | Process inspection | No |
| 3 | **Listening** — something answers in the OpenAI shape | Port sweep + `/v1/models` | No |
| 4 | **Self-describing** — it named itself or listed models | `owned_by`, model list | No |
| 5 | **Agent-aware** — it can name its configured agents, provider and model | Adapter, or MCP probe | Usually |
| 6 | **Activity-aware** — it can report in-flight or recent requests | Adapter | Yes |
| 7 | **Caller-attributed** — we know which agent made *this* request | Instrumentation on both sides | Yes |

Rungs 0–4 are **vendor-neutral and must stay that way.** They are the reason Sea-Star
works with a runtime released last month. Rungs 5–7 are where adapters earn their keep,
and where a registry legitimately lives.

**The ordering is the contract.** A thing that answers on a port is a runtime even if we
have never heard of it, and the model list it returns is real information regardless of
whose server it is.

### The degradation contract

> Show the **highest rung reached**, and **show the rung**.

Never display a claim above the rung actually established. `Configured`, `Reachable`,
`Active`, `Unavailable`, `Last reported` are different facts and must never be collapsed
into one another. A configured route is not a running model; a loaded model is not an
active request; a healthy endpoint does not prove a harness is using it, and never
identifies the caller.

---

## 3. MCP is the generic adapter

Because MCP is a standard rather than a product, an unknown harness that speaks it can be
**asked** rather than **known**. This is the mechanism that makes degradation cheap, and it
is why the answer to "a new harness appeared" is never a longer list.

- **Ask, don't guess.** "Does it advertise MCP, and what tools?" is a rung-5 probe that
  works on software released last week.
- **A missing adapter is a degraded rung, not a failure.** Unknown harness at rung 3 is a
  perfectly good product state.
- **Prefer the standard to the special case.** When a generic protocol answers a question
  a per-harness adapter was going to answer, the protocol wins and the adapter is deleted.

### Symmetry: what we can prove must be callable

If a fact is only ever visible on screen, a harness cannot see it — and the cockpit's
entire value is that it knows things the harnesses do not. Anything Sea-Star claims about
the machine should be reachable **over MCP as a tool**, not only drawable in the app.

This is why "registered in Osaurus" and "useful to Osaurus" are different milestones.
Registration is a config block. The second requires that the exposed tools answer the
questions a host actually asks.

---

## 4. Privacy and the standing defaults

Unchanged and not up for casual amendment. These predate this document and this document
does not weaken them.

- **Nothing leaves the machine** unless the founder explicitly configured that endpoint and
  approved it. On-device by default; no cloud fallback.
- **No telemetry, no background monitoring** beyond what the founder has explicitly asked
  for; nothing written outside the vault and `.seastar/`.
- **Never store by default:** prompts, model outputs, tool arguments or results, private
  agent prompts, config exports, secrets, note contents. Activity records carry *who*,
  *what route*, *when* and *how we know* — not *what was said*.
- **The founder's external drive and any mirror of it** are off-limits to every agent and
  harness unless he asks for a specific item in writing.

Evidence discipline follows from this: every activity claim carries its **source** and
**confidence**. A hypothesis is labelled as a hypothesis.

---

## 5. Tiers

- **Tier 1 (values, never bend).** §1 and §4. Changing either requires the founder to
  rewrite the clause himself.
- **Tier 2 (architecture bets).** §2 and §3 — the capability ladder, the degradation
  contract, MCP-first. These are the current best design, not eternal truth. Locked
  against casual drift, not against a reasoned pivot.

A locked spine that survives a real pivot unchanged was probably never tested. Treat
friction from the founder as the signal that a clause needs amending, not that he needs
correcting.

---

## 6. Known debt against this document

Recorded so the gap is visible rather than rediscovered. Not urgent; each is a normal
piece of work.

1. **`harnesses.py` gates on a bundle-id allowlist.** An app outside
   `KNOWN_HARNESS_APPS` is skipped entirely, not shown as unknown. This violates §1
   directly. The fix is a rung-1/2 path for unrecognised apps that floats them with an
   honest "not connected, not recognised" state.
2. **No MCP-based activity probe exists yet.** §3 is written but unbuilt; rung 5 by
   protocol is currently unavailable.
3. **The cockpit's findings are not exposed as MCP tools.** Symmetry clause unbuilt.
4. **Rung 7 has no instrumentation.** Per-agent, per-request attribution across harnesses
   remains the largest open question in the product.
