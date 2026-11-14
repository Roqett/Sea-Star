# The browser 3D canvas — investigated, not built

2026-10-07. Asked for by the founder: *"investigate whether or not we can use an
internal browser style for the 3D side… it sounds like it was considered, then
disconsidered, then considered again. It was all over the shop. I think it can be
done."*

**Verdict: it can be done, it is not the cheap option, and the recommendation is not
to build it yet.** The measurements are below so the decision rests on numbers
rather than on the project's memory of having gone back and forth.

---

## Why it looked like it flip-flopped

The record is genuinely mixed, and the confusion is legible in the documents:

- **Spec D3** (`.trae/specs/mac-app/spec.md:114`) locks the graph to *"Embed the
  codebase-memory web UI via `WKWebView`, restyled to the palette"*. That decision
  has been superseded in spirit and in code, but **the line was never edited** —
  it is a locked founder decision and agents flagged rather than amended it.
- **PROGRESS 2026-09-26** records T4.2 (the `WKWebView` embed) as *superseded by the
  native renderers*, and marks it *"confirm with the founder before closing"*.
- **Founder note 5** (2026-09-30) reopened it as a *different* proposition: not
  codebase-memory's application, but a **dumb canvas** (`3d-force-graph`) fed our
  own model. The note's own distinction is the load-bearing one and it is correct:

  | | a **rendering library** | a whole **application** |
  | --- | --- | --- |
  | What it is | `3d-force-graph` — a canvas we feed | codebase-memory's explorer |
  | Data shape | ours | its own backend/API |
  | Cost | one bundled page | run their engine beside ours, or write an adapter |
  | Verdict | clean | licence check, update schedule, two systems |

So the flip-flop was never really about the technology. It was **one decision slot
holding two different questions**, and the honest resolution is that they have
different answers. The library is feasible. The application embed is not.

---

## What it would cost, measured

Not estimated — measured, from the actual published artefact.

| | Measured |
| --- | --- |
| `3d-force-graph` 1.80.1 | MIT, 6.4k stars, actively released (Oct 2026) |
| Minified bundle | **1,389,954 bytes** (1.39 MB) |
| Gzipped | **363,985 bytes** (364 KB) |
| Current Release `.app` | 4.8 MB |
| SceneKit it would replace | 1,149 lines across `GraphScene.swift` + `GraphSceneView.swift` |
| WebKit | **not currently linked** in `project.yml` — this is a new framework dependency |

The 364 KB is the honest number to plan against; a DMG compresses, so that is
roughly what ships. Against a 4.8 MB bundle it is about **7%** — acceptable. The
found note asking to *"measure the spec's size gate"* was citing a gate that does
not exist (that invented citation is logged in the 2026-10-02 handoff), so the
measurement is done here instead.

`three` is the real dependency underneath (`>=0.179 <1`), and it is already inside
that 1.39 MB figure — so there is no second large package to worry about.

---

## What it buys, and what it costs beyond bytes

**Buys:** orbit/fly/trackball camera controls, click-to-focus, directional
particles along links (the crawl the flat pool hand-builds), highlight, and the
`dagMode` layouts. That last one is the interesting one for us: **the cascade is a
DAG**, and `dagMode: 'radialin'` or `'td'` would lay out vault → harness → agent →
inference by *rank* rather than by hand-tuned ring positions.

**Costs beyond bytes, all real:**

1. **A new framework dependency.** WebKit is a large system framework. It is
   Apple's, so no licence question, but it is a new surface in a project whose
   whole argument is that it is *local-first and minimal*.
2. **A rendering seam.** Today `EntityGraphModel` is the single source of truth and
   both renderers read it. A web canvas means the model must be **serialised to
   JSON and crossed into a `WKWebView`**, then hover/click/focus results crossed
   back. Every future model change becomes a two-place change. The existing tests
   pin the model; they would not pin the boundary.
3. **Node glyphs.** `3d-force-graph` draws **spheres**. Sea-Star's whole identity is
   the eight-armed sea-star (`SeaStarGlyph`, the founder's real art, the caustic
   shimmer). Restoring the glyph inside a WebGL canvas means either an SVG-to-texture
   path or a custom `nodeThreeObject`, which is real work and can look pasted-on.
   The current SceneKit room has the same problem, which may be part of why it
   reads as a blob.
4. **Motion discipline.** It auto-runs a simulation. Reduce Motion and the
   existing `SeaStar.cockpitOpen` gate would both have to reach into the page.
5. **A DMG with a browser in it.** Embedding a whole web engine to draw twelve nodes
   is the kind of thing that is defensible for `codebase-memory`-scale graphs and
   questionable for ours. Our graph has **~13 nodes** — the founder's own note said
   occlusion is not the blocker at that scale.

---

## The honest comparison

The founder's complaint about the flat pool is real and recorded: it *"still crowds
at thirteen ring points plus the new wires"* (D-017 open item 5). That is a
**layout-density** problem, not a **rendering-power** problem. A force simulation
would spread those thirteen nodes — but so would fixing the ring layout, and the
ring layout is a few dozen lines rather than a new framework and a rendering seam.

**The split panel is a better idea than the web canvas.** The founder raised it in
the same breath: *"I do kind of like potentially having a split panel for that too."*
A split panel (Facts/Path beside the graph) attacks the actual complaint — too much
in one box — with none of the costs above, and it uses the two readings that already
exist and already share one model.

---

## Recommendation

1. **Do not build the web canvas yet.** Revisit if the graph ever needs
   codebase-memory scale, or if the founder decides the sea-star glyph cannot be
   made to work in 3D at all.
2. **Fix the crowding natively first** — ring spacing, and whether a satellite's
   spokes should be drawn at all in the whole-pool reading. Cheap, reversible, and
   it tests the same hypothesis.
3. **Build the split panel** if the founder wants more room; it is the change that
   actually addresses "too much in one place".
4. **Spec D3 still needs amending**, in one line, whenever the founder settles it.
   This document is the evidence for that amendment; it does not make the decision.

## Open, for the founder

- Does the 3D room stay as a third reading, or does the split panel replace it?
- If the sea-star glyph is non-negotiable, a WebGL sphere is the wrong renderer
  regardless of which library draws it — which is a stronger argument for fixing
  the native room than for the web canvas.

Nothing here is built. Nothing here is locked.
