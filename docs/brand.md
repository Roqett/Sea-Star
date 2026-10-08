# Sea-Star — brand and style

The single reference for how Sea-Star looks and sounds, assembled from records that
already existed and had drifted apart. Sourced from
[`macapp/SeaStar/Support/Palette.swift`](../macapp/SeaStar/Support/Palette.swift) (the
code, which is authoritative), [`docs/HANDOVER-mac-app.md`](HANDOVER-mac-app.md) §5 (the
Carpet Sea Star rationale), and [`docs/foundation.md`](foundation.md) (the voice).

**Where it came from.** There was no stylesheet in this repository until now. The
palette lived in code with its reasoning in a handover doc, and the brand language
was implicit in the founder's own words scattered across three sessions of notes.
This file gathers them so a next agent does not have to re-derive it.

---

## 1. The name

| | |
| --- | --- |
| Product | **Sea-Star** |
| Repository | `Roqett/Sea-Star` — the founder's personal account, so the history shows on his profile |
| Licence / bundle id | **Up Periscope** — the *product identity*, not a GitHub org |
| Python distribution | `seastar-mcp` |
| Mirror | Codeberg, `Touretro/theSeaStar` — a deliberate second home, **not** a mirror of the branch |

"Up Periscope" is the umbrella. Sea-Star is one project under it.

## 2. The animal

The **Carpet Sea Star**, *Meridiastra calcar* — native to the founder's own coast
(Yorke Peninsula, South Australia).

Three reasons it is the right creature, and they are the brand's whole argument:

1. **It is local.** A species from this coastline, not a generic marine icon.
2. **It is eight-armed**, like the octopus in the original logo.
3. **Its colourways are near-infinitely genetically driven** — *your* rockpool is
   unlike any other. Which is exactly Sea-Star's ethos: every person's setup adapts
   to their own machine.

And the behaviour, which is the tagline: **a sea star holds on tight to its rock and
doesn't let go.** Sea-Star does the same with your notes, and helps you find the
right one.

> The source art is **eight-pointed, not a five-arm sea star.** This is recorded
> because a future agent will look at the geometry and try to "fix" it.

Reference photography is in `assets/reference/` and is **git-ignored on purpose** —
third-party images, not redistributable. The hex values below are the durable record.

## 3. Colour

Cold, dark canvas, bright glowing accents. The same feel as the codebase-memory
graph, lit from the rockpool instead.

| Role | Hex | Where it is used |
| --- | --- | --- |
| Canvas / pool | `#10131A` | The dark ground. Also the fixed starfield pool. |
| Deep purple | `#4B2E83` | Depth, structure |
| Plum / maroon | `#7A1F3D` | **Remote / API inference** — the one thing that leaves the house |
| Mauve | `#B0859E` | Sea-Star itself, and the pool's structural rays |
| Electric blue | `#2F7FE0` | The app's primary UI accent, wires, focus |
| Teal | `#26A69A` | **Local inference** — "about this machine" |
| Neon green | `#8BD450` | Models, and the "live" half of a connection |
| Vermilion | `#E2402A` | Alert, the flagged case in the ledger |
| Orange | `#F5842B` | Live connection, warming toward green |
| Bone / cream | `#EDE3D2` | The vault, and primary ink on the dark canvas |

### The meanings are load-bearing

Accents are assigned to *meanings*, so the same idea always glows the same colour:

| Thing | Colour | Why |
| --- | --- | --- |
| **Vault** | Bone | The pool is the paper your notes are on. The one thing everything sits in should not compete with a model's green. |
| **Harness** | Electric blue | The app driving Sea-Star. |
| **Local inference** | Teal | About *this machine*. |
| **API inference** | Plum | What is *coming in*. The palette's most sober closed red, because it is the only node that leaves the house. |
| **Model** | Neon green | What an endpoint serves. |
| **Agent** | Warm (orange) | The person's own personas — the crew *they* built — glowing apart from the cool infrastructure they run on. |
| **Sea-Star** | Mauve | The palette's quiet structural voice. Deliberately **not** bone: the hub and the memory it lives in must not read as the same kind of thing. |

**Liveness is a pair, never one colour.** A wire or bar carrying live traffic is
**orange → green, moving**. A wire that is merely a stated binding is
**blue → white, still**. This is D-002's amplitude rule and it holds everywhere.

### Two layers, deliberately

- **Chrome** (panel background, ink) is **adaptive** — an `NSColor` dynamic provider
  keyed on `bestMatch(.darkAqua/.aqua)`, so the cockpit is legible in both
  appearances. Light canvas `#F7F3EC`, light ink `#1C1A17`.
- **The pool** (the starfield's ground) is **fixed dark** in both appearances. A graph
  of glowing orbs only reads right on a dark ground, so it stays the rockpool even
  when the chrome turns light.

## 4. Type

| Use | Face |
| --- | --- |
| Headings, titles | The system UI face, semibold |
| Labels, headings in-panel | **SF Mono**, semibold, small caps, tracked out |
| Values, facts, logs, endpoints | **SF Mono**, regular |

Mono is the house voice and it is not decorative. This app is about machine facts,
and mono is how machine facts are set. The graph's in-pool labels also use mono at
9pt.

## 5. Motion

- **Nothing moves unless something is true.** The breath is reserved for a node that
  actually answered. A still star is reporting that nothing is on its port.
- **The pool only animates while the popover is open.** One `SeaStar.cockpitOpen`
  environment gate covers caustics, grain, drift and the SceneKit simulation.
  Closing the panel does not stop the server or the MCP connections.
- **Reduce Motion is honoured everywhere** — caustics off, no drift, no crawl, no
  auto-spin.
- **No signal means still**, which is the safe failure.

## 6. The marks

| Asset | Use |
| --- | --- |
| `assets/sea-star.png` | README front image |
| `assets/ss-icons/S_S_1*.png` | The founder's icon art — the `S_S_1` devices (pentagon-and-dot per arm, rosette at the hub) |
| `assets/Nudi_strips_3px/` | The nudibranch strips. **Blue-white = wiring. Green-orange = liveness.** |

The menu-bar glyph is rendered as a **template**, so the system tints it (white on a
dark menu bar, black on a light one) and the fine line art survives both appearances.
It carries a **solid band partway out from the fuzzy centre** — a sea-star's body with
the ray tips free — because the bare cut read as a snowflake. `bandDiameter 0.55`,
`bandWidth 0.12`; those numbers were chosen by eye against rendered alternatives.

Four faces are held in one roster (`IconRoster`) and the app **rerolls to a
different face** on every server start and stop — never the one that just went away.
This is the "open and shut" Easter egg, and it makes the state change unmistakable.

The app is `LSUIElement` (no Dock presence), so **no `.icns` app icon is required.**

## 7. Voice

**Plain, concrete, and specific.** Written for someone who does not use a terminal
and has not read the code.

- **No jargon without a gloss.** If a term must appear, define it in the same
  sentence. Assume no prior knowledge — not of MCP, not of YAML, not of ports.
  The founder did not know what a "smoke test" was; write for the person who also
  doesn't.
- **Lead with the thing the reader gets**, not the mechanism. "Your notes answer,
  with a link back" — not "implements RAG over a local vector index".
- **Admit the limits, in the same breath.** An unreleased product that says "the
  engine is finished and tested; the app is in build" is more trustworthy than one
  that oversells.
- **Never claim what was not observed.** This is not only a product rule, it is the
  whole design: *show the highest rung reached, and show the rung.*
- **No hype words.** Not "revolutionary", not "powerful", not "seamless". If a claim
  cannot be measured, cut it.
- **British/Australian spelling**, full stops, contractions welcome. Write like a
  person explaining something to a friend.

### Words we use, and words we don't

| Instead of | Say |
| --- | --- |
| Leverages, harnesses your workflow | Works with the tools you already use |
| Seamless integration | Plugs in — here's the block you paste |
| Privacy-first | Nothing leaves your machine. Ever. |
| Powerful local LLM | Runs on your own model, on your own Mac |
| Utilise | Use |

## 8. What we never claim

- **No telemetry, no monitoring, no analytics.** Nothing written outside the vault and
  `.seastar/`.
- **Nothing leaves the machine** unless the founder explicitly configured that
  endpoint and approved it.
- **No competitor claims**, and no benchmark numbers we have not measured ourselves.
- **No screenshots we have not taken.** Every image in the repo is a real capture.

## 9. Open for the founder

- The tagline is currently *"One click's ease. Nothing leaves your house."* — the
  founder's words, and the only tagline in the repository.
- `assets/sea-star.png` predates the current icon art and has not been re-exported.
- No wordmark exists; the front image is a raster mark.
