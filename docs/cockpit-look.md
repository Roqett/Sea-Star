# The cockpit, reconceived

An audit and reconception by the agent, 2026-10-02. This supersedes the two earlier drafts,
which drifted into a two-dimensional flow chart. That was the wrong direction and is gone.

The founding constraint, in the founder's own words: *"you don't actually need [the linear
look]. We want an interactive view… that's the point of having it as the 3D graph that Codebase
uses. You click on something or hover over it, tells you what it is. You click on it and it
focusses and then you see the latent possibilities in more detail."*

---

## 1. What the cockpit is

One window, two readings of the same machine, and nothing else.

- **The graph** — a single interactive field of sea-stars you move through. Hover names a
  star; click focuses it; focus brings its neighbourhood forward and shows what it can become.
  The sea-star glyphs, the caustic shimmer, the slow drift, the glow — all stay. This is the
  reading for people who want to *see* their machine.
- **The list** — one text panel: the four rows (Vault / Harness / Agent / Inference), a
  `Working now` line, and the honest evidence line under it. This is the reading for people
  who want the *facts*.

Both read the same model, so they can never disagree. That is the whole product on this axis:
a spatial answer and a verbal answer to one question — *what is happening on my machine?*

## 2. What crept in (the audit)

Three independent switches were shipped that should have been one choice each:

| Switch | Current | What it should be |
| --- | --- | --- |
| Reading | Graph / List | Graph / List (fine) |
| Graph depth | Flat / Deep / **Both** | **one** interactive graph |
| Text layout | Stack / Chain / **Both** | **one** layout |

`CockpitPanel.swift` carries the two text experiments — *Variant A · Stack* (vertical) and
*Variant B · Chain* (horizontal) — plus a `both`. `CockpitPopoverView` carries the two graph
renderers — `EntityGraphView` (flat starfield) and `GraphSceneView` (the 3D room) — plus a
`both`. Two of everything, then two "both"s on top.

Those `Both` options were comparison instruments, exactly the thing D-002 said to *"leave
behind once a reading is chosen."* They were never meant to ship as modes. The founder's own
rule from the 30 September session says why they read as clutter: *"main bin = stuff that's
going to GitHub; side bin = experiments."* The horizontal/vertical text variants and the
second graph renderer are side-bin experiments that landed in the main bin. Not a character
flaw — it is literally what a fork is for, and nobody had shown how to use one. That is now
understood, and the fix is mechanical: pick one, retire the rest.

## 3. The graph: one field, not two, and not a chart

One interactive field. The sea-star marks stay exactly as they are — the founder is clear he
wants them kept. What changes is that there is **one** graph and its behaviour is the point:

- **Hover** → the star names itself and says what it is, without a click.
- **Click** → focus. Everything unrelated fades, the neighbourhood pulls forward, and the
  card fills with that entity's facts.
- **Focus on inference** → its models appear, and the one actually loaded or working is lit by
  the live ribbon.
- **The live ribbon** (green→orange, moving) marks what is carrying work *now*; the resting
  ribbon (blue→white, still) marks what is known but idle.

The 3D room was an attempt at exactly this and it works as a concept; it was left in a broken
camera/scale state ("the blob"), which is a bug to fix, not a direction to abandon. The flat
starfield is the same concept without the freedom to move. They are two renderings of one idea
that should collapse into one working interactive field.

## 4. The list: one panel, one layout

Four rows — Vault / Harness / Agent / Inference — the D-001 split that was decided on
2026-09-28 and never finished in the UI. Under them, `Working now`, observation-only, with the
evidence line that says which rung each claim stands on. Plus, now that the bridge carries it,
which MCP servers and hosts are attached.

**Pick one of Stack or Chain and retire the other.** The choice is a single founder decision;
the loser is deleted, not kept as a mode.

## 5. Inference: local is about the machine, API is about what's coming in

The founder's distinction, which the graph must now carry:

- **Local inference** (oMLX, Ollama, LM Studio) — *about the machine.* Its models are shown,
  and their state matters: available / loaded / working. The machine's load is the story.
- **API inference** (OpenRouter, DeepSeek) — *what is coming in.* One node, one colour, and the
  panel says what it is and that it is answering; it does **not** enumerate four hundred
  models. A remote endpoint is a single fact, not a library.

So inference needs **two accents** — one for local, one for API — because they answer
different questions. Vault, harness, agent and model keep their existing colours. `latent`
ceases to be a kind and becomes what it always was: a rung ("installed but idle").

## 6. What gets deleted

- The `Both` options on both switches, and the switch mechanics they rode on.
- One of `EntityGraphView` / `GraphSceneView` (whichever loses §3), and the losing text layout.
- The per-node hue smear at `EntityGraphView.swift:857` — narrow it, keep the C-star variation.
- The duplicate readout card (one per pane becomes one, period).

## 7. Open with the founder

1. **Which graph renderer survives** — the interactive room, or the flat field — and whether
   the room's framing bug gets fixed or the flat view grows the freedom instead. Same concept
   either way; the founder picks the body.
2. **Stack or Chain** for the list.
3. **The API accent colour.**
