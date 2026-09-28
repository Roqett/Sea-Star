# Decisions

Architecture, UX-flow, and product-value decisions, in the order they were made.
`AGENTS.md` requires a decision to land here when it affects any of those three.

The product's binding principles live in [`docs/foundation.md`](docs/foundation.md) and are
not duplicated here. This file records *choices made in the light of* those principles.

Each entry is immutable once accepted. A reversal is a new entry that supersedes the old one
and says why it was wrong — the same append-only discipline as the changelog.

---

## D-001 — The panel splits `Harness`, `Agent` and `Inference`; the Harness row keeps its picker

- **Date:** 2026-09-28
- **Status:** Accepted
- **Affects:** UX flow, product values
- **Founder input:** the ontology was raised, and the founder explicitly declined to resolve it
  ("I don't know … I want you to come up with some ideas. That's the point."). The decision
  below is therefore the engineer's, made under `AGENTS.md`'s one-recommendation rule.

### The problem

The `Harness` row renders `"\(report.runtime) · \(report.baseURL)"` — an app name and a server
URL fused into one string. Three different facts share a field:

1. **which app answers** (a harness),
2. **which persona inside it answers** (an agent),
3. **where the model call goes** (an endpoint + model).

Fusing them means the endpoint is displayed as though it were an identity. It is not: two
different harnesses routinely sit on one endpoint, and one harness can be pointed at a
different endpoint. The row is a collapse of the ontology, which is what the split exists to
undo.

### The decision

Four rows, each carrying one kind of fact:

```
Vault      → the knowledge source and directory being read
Harness    → the execution surface: which app answers        [picker retained]
Agent      → which persona inside that harness answers        [additive]
Inference  → the endpoint *and* the selected model
```

**The Harness row keeps its picker.** The reasoning matters, because the alternative was
considered and rejected:

- Switching harness is a **real, working, already-shipped action**. The picker is not the
  defect.
- The **URL in the harness row** is the defect. That is the thing to move.
- So this is a **move, not a removal**. Relocating selection to the `Agent` row would have
  deleted a functioning control in order to fix a display collapse — trading a working
  affordance for a tidier label.
- `Agent` is therefore strictly **additive**. It appears when a harness actually reports a
  roster, and degrades to an honest "none configured" when it does not.

### Consequences

- The endpoint string is removed from the `Harness` row and appears under `Inference`, where
  it is a property of a call rather than of an app.
- `Agent` must not pretend to be generic. The engine's current `agents[]` is **one Osaurus
  adapter**, and `AgentInfo` carries no harness identity. Until agents carry a harness, the
  row must show scope honestly rather than implying a global roster.
- Every row is subject to the foundation's degradation contract: show the highest proven
  rung, and show which rung was proven. "Unknown" and "not configured" are different states
  and must not share a string.
- `Working now` is **observation-only** and sits beneath the four rows. It may not display a
  prompt, an output, or a persona acting, because the activity stream that would prove those
  does not exist yet.

### Revisit when

- The activity-event stream lands. `Working now` can then carry evidence-backed liveness, and
  the `Agent` row's scope question becomes answerable rather than rhetorical.
- `agents[]` gains a harness identifier in the bridge, making per-harness rosters provable.
