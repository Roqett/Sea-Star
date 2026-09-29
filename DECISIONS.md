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

## D-002 — Two windows, two independent axes, one shared model

- **Date:** 2026-09-30
- **Status:** Accepted
- **Affects:** mac-app — cockpit panel (`SeaStar.panelLayout`), entity graph
  (`SeaStar.graphDepth`, Flat 2D + Deep 3D), animation scheduling (`SeaStar.cockpitOpen`),
  node colour/glow/hover, liveness bars, future input routing
- **Founder input:** "do a stocktake of the 2 instances and get a game plan for both of them
  that's coherent"; the idle 2D nodes "should be essentially colour coded for whether or not
  that's a model or an agent … differentiated by the glow like if it's active it just has the
  glow, but all of them when you hover over more or less should display what they are. People
  don't like clicking on things so much"; "I don't understand why any of that animation can't
  just work whenever the actual panel's open … They close it, it shuts, and the MCP
  connections maintain. That's it."; the orange/green bars should move "a little bit more
  obvious without too much system strain"; input is "flexible … down the track" — voice
  ("cycle through all available models in that server") and keyboard cycling both named,
  voice his preference.

### The problem

Comparing the two readings metastasised. The founder asked to compare two *text*
structures, agreed in passing to also display both *graph* types, and the cockpit ended up
with both-of-each in both windows at once — "a whole lot of stuff", a cascading cluster
where tidying one view unsettled another. Beneath that sat four defects read off
screenshots and usage: idle 2D nodes were grey, so a model and an agent were
indistinguishable at a glance; the 3D room was "blown out" beside the flat star shells'
better definition; animation ran while the popover was closed (~23% CPU for nobody); and
the liveness bars' motion was too subtle to notice. There was no single statement of what
each window is *for*, so every session's tidying was a local judgement with no anchor.

### The decision

- **Two windows, one axis each, defaults show one design.** The text window arranges the
  four rows via `SeaStar.panelLayout` — **Stack** (default), **Chain**, **Both**. The
  graph window picks its renderer via `SeaStar.graphDepth` — **Flat** (default), **Deep**,
  **Both**. The keys stay independent: one answers "how many dimensions", the other "how
  are the rows arranged". Comparison (`Both`) is opt-in *per window* — a person may A/B
  either axis without the other changing under them, and nobody lands on four things at
  once.
- **One model feeds both graph renderers.** Flat and Deep consume the same
  renderer-independent `EntityGraphModel`, so the two renderings cannot disagree with each
  other or with the rows (the same rule D-001 set for rows-vs-graph).
- **Colour codes kind; glow codes liveness; hover codes identity.** Every node wears its
  kind's accent — vault teal, harness and latent electric blue, model neon green, agent
  orange — hue-shifted by a deterministic fraction of its own id, so one kind reads as a
  genre with variation (the C-star treatment) rather than clones. Glow is earned: full
  glow only when active or selected, a dim breath when live, plain definition when idle.
  Hover reveals every node's name and kind without clicking; a click still routes through
  the existing `selectVault` / `selectHarness` / `selectModel` calls.
- **Blue-white remains the resting strip; orange-green marks active graph connections
  only.** Consistent with the founder's earlier ruling; brighter variants to come from the
  founder later.
- **Animation is scoped to visibility.** The popover delegate writes `SeaStar.cockpitOpen`
  (default **false**); an environment value carries it to every animated surface —
  caustics, grain, the 2D timeline, the SceneKit render loop, the liveness drift. Closed
  means still; no delegate signal also means still (the safe failure). The server and its
  MCP connections are untouched by the gate. Reduce Motion stills the same surfaces
  regardless.
- **Liveness motion must be legible, not expensive.** The orange/green bar doubles its
  sweep (2× scale, 8pt travel) with no new timers or repaints — amplitude, not frequency.
- **Interaction stays hover-first, with keyboard and voice planned as equals.** Discovery
  happens on hover because people don't like clicking. Planned: keyboard cycling (focus a
  node, step through the models the selected server offers) and voice commands ("show me
  what servers we're using, cycle through the models available"). Both must reach the same
  actions the pointer reaches; neither may become a precondition for understanding the
  graph.

### Consequences

- Four defaults keys now shape the cockpit (`cockpitMode`, `panelLayout`, `graphDepth`,
  plus the non-visual `cockpitOpen`); the spec must describe all four, and preference
  resets affect only presentation, never privacy.
- The `Both` modes cost width (660pt text, 960pt graph) and exist to be *left behind* once
  a reading is chosen — a comparison instrument, not a third design.
- A closed popover is now genuinely idle; anything added later that animates must opt in
  through `seaStarCockpitOpen` or it will run while closed.
- Hue-shifts make colour load-bearing: any new entity kind must ship an accent in both the
  rows and the graph, or it reads as unkinded grey — which this decision exists to prevent.
- Voice and keyboard are promised as roadmap, not built; the spec records them so
  hover-first is not mistaken for the finished interaction model.

### Revisit when

- The founder picks a reading for either window — the losing layout there can then be
  pruned and its `Both` option retired.
- Voice or keyboard input actually lands — at which point the roadmap paragraph in spec
  §8.7 becomes a section describing real affordances.
- Brighter orange/green strip art arrives from the founder — swap the art, keep the
  amplitude rule.
- An activity-event stream exists (per D-001) — `Working now` and the glow rules may then
  encode *usage* rather than endpoint liveness.
