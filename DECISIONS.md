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

## D-003 — The comparison modes retire; the cockpit has one reading per axis

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** mac-app cockpit — graph depth toggle (`SeaStar.graphDepth`), text layout
  toggle (`SeaStar.panelLayout`), popover width, UX flow
- **Founder input:** "the graph panel isn't meant to have the two graphs in there";
  "they ended up being 4 of them and you click between them and it just ended up being
  spaghetti"; "there's not meant to be a split panel"; the simplicity brief ("think Jonny
  Ive"): one interactive graph and one text panel.

### The problem

D-002 shipped Flat/Deep/Both and Stack/Chain/Both as persistent, remembered modes. The
`Both` options were comparison instruments — D-002 itself said they *"exist to be left
behind once a reading is chosen"*. They were left behind never, and instead became two
extra shipped modes per axis: two of everything, then two "both"s on top. The founder
called the result spaghetti.

### The decision

Retire `Both` from both switches. `SeaStar.graphDepth` becomes Flat/Deep and
`SeaStar.panelLayout` becomes Stack/Chain until the founder picks a reading for each axis,
at which point the loser is pruned (D-002's own revisit clause). A stored `"both"` value
degrades to the axis default through the existing `resolved(from:)`, never to a blank
panel.

### Consequences

- The graph panel is a fixed 600pt wide and the list a fixed 360pt; the 960pt/660pt
  comparison widths are gone.
- `PanelLayout.isWide` and the compare layout (`CockpitPanel.compareLayout`) are deleted.
- Swift tests now expect two layouts; the three-layout test retired with the mode.
- One graph and one text panel is the shape of the cockpit again; the surviving renderer
  and layout are founder picks recorded here when made.

### Revisit when

- The founder picks the graph renderer — including the open question of a bundled,
  offline web canvas at codebase-memory quality — and the text layout. Retire the losers
  and fold the renderer decision in as its own entry.

---

## D-004 — A harness is the app driving Sea-Star; an endpoint is inference. The rung is drawn.

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** architecture (bridge contract, graph model), UX flow, product values
- **Supersedes:** part of D-001. D-001 split the *panel rows* correctly but left the app's
  data model fused: `ServerController.harnessOptions` held endpoint probes and was drawn as
  the `Harness` row's contents. The founder's correction — *"server isn't one of an actual
  item because we decided to call it inference, as in where the models are coming from"* —
  names the error. D-001's row split stands; its naming did not follow through into code.

### The problem

Three things were being filed as one:

1. **the app driving Sea-Star** (Atomic Chat, Xcode, DeepSeek Harness) — a *harness*,
2. **where models come from** (127.0.0.1:1337, 127.0.0.1:8009) — *inference*,
3. **how far either got** — collapsed to a single grey "not connected".

The founder's tests of the app found the consequences: clicking a harness showed a bare
count ("5 models") and its URL; the apps actually on the machine were invisible; and a
running app and a dormant install looked identical.

### The decision

Four things, stated once:

- **`Kind.harness`** is an app that drives Sea-Star. It is live only when the engine's own
  connection record proves it (a `sea-star serve` process whose parent chain reaches the
  app). `Kind.latent` is deleted: an unattached harness is a harness at a lower rung, not a
  different kind of thing.
- **`Kind.inference`** is where models come from. Local endpoints are teal, a remote API is
  plum. `HarnessOption` is renamed `InferenceOption` and `harnessOptions` →
  `inferenceOptions`; the endpoint picker moves out of the panel's `Harness` row into
  `Inference`, where the ontology already put it.
- **The rung is drawn.** `harnesses.py` reads the process table once and reports
  `present` / `running` per app; `connections.py` already reports the top rung
  (`caller-attributed`). The bridge carries `rung` on every latent harness, and the graph,
  the panel row and the readout card all say which rung, never a yes/no.
- **Readouts name things.** The founder's rule — *"we don't want to see just some text
  saying five models"* — is implemented as `nameList`: an endpoint lists the models it
  serves, a model lists the endpoints offering it and the personas riding it, an attached
  harness lists its pid, its start time and the tool it calls (`ask_seastar`). Rows that
  would only restate the title are omitted.

DeepSeek Harness is added to `KNOWN_HARNESS_APPS`. The harness the founder is talking to
therefore appears on its own graph — at the rung it has actually reached.

### Consequences

- `GraphNode.Kind` is `vault, harness, inference, model, agent`; node ids become `harness:<bundle-or-client>`
  and `inference:<base-url>`. `activeHarnessID` → `activeInferenceID`.
- The `Harness` panel row is a reading, not a picker: the app cannot make another app attach
  itself, and a control that looked load-bearing would be a lie.
- The per-node hue smear in `EntityGraphView` narrows from ±25% to ±6% of a turn. A quarter
  turn was enough to turn a plum API red and a teal local runtime blue, which was
  decoration eating the one distinction the palette carries.
- Swift graph tests assert the four live nodes (attached host, endpoint, current model,
  riding agent), that an unattached harness has no edges and an attached one is wired to its
  vault, and that an endpoint readout names its models rather than counting them.

### Open

- **The top rung for DeepSeek Harness.** It is drawn at `running` today — present and up,
  not attached. It reaches `caller-attributed` ("Driving Sea-Star now") only when DSH
  registers Sea-Star as an MCP server, at which point the existing connection record picks
  it up with no further code. That is a configuration change in another app in the factory
  and needs the founder's word.

### Revisit when

- The founder decides whether DSH should attach Sea-Star over MCP, and picks the graph
  renderer (D-003's open clause).

---

## D-005 — Reconnaissance is triggered, not watching; recognition is by vocabulary and register, never by a list of app names

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** architecture (new `recon.py`), product values, UX flow
- **Founder input:** *"we need to work out some sort of onboarding where SeaStar works out
  what's on the system and then is able to detect anything in the future that behaves anything
  like AI or agentic behaviour"*, and, on the privacy line: *"that's nothing watching — it's
  heads-up reconnaissance … a major point of the app is to be a cockpit, to let the user know
  what's going on on their machine … we really need to get away from those sorts of rules that
  all sound very local sovereign but can be absolute easily, but shouldn't be when it comes
  down to common sense."*

### The problem

`KNOWN_HARNESS_APPS` was a hardcoded list of ten bundle ids. It violates the foundation's own
lead clause — **"no name is ever a precondition"** — and it fails in practice: the machine
carries 31 apps, and the list missed Atomic Chat, which is the founder's current benchmark
harness. A list of product names is stale within a fortnight.

An evidence probe was run before deciding anything (recorded in `docs/PROGRESS.md`):
inspecting bundles for AI evidence found **nothing** for thirteen apps over 400MB, including
two that are purely AI. Behaviour and vocabulary found six of the founder's seven apps. The
method was never the problem; the word list was.

### The decision

1. **A new module, `recon.py`, reads the machine's own process and socket tables.** It reports
   every listening port and every live outbound connection, each **attributed to the `.app`
   that owns the process tree** — so a model server held by a bare `python3.11` three rungs
   below the app is still credited to the app. No name list takes part.
2. **Triggered, never watching.** Nothing in the module starts a thread, schedules itself, or
   remembers anything between calls; it cannot cause a read. The read happens because the
   person launched, opened the cockpit, or asked for a report. The foundation's *"no
   background monitoring"* is therefore honoured as written — **background** means unattended
   and continuous, and this is neither. No value is rewritten and none is weakened: nothing
   leaves the machine, nothing is written outside `.seastar/`, and no process runs when
   nobody is looking.
3. **Interception is a different thing and stays out.** Reading *who is connected to whom* is
   reconnaissance of the person's own machine. Reading the *contents* of those connections
   needs a proxy and a trusted root certificate installed, which is genuinely invasive; it is
   not proposed and would need its own decision and a stated reason.
4. **Recognition is vocabulary plus register.** A loopback port is inference if its process
   tree speaks runtime vocabulary (`llama`, `mlx`, `ollama`, `vllm`, …) **or** its owning app
   is one the machine has already agreed on. The vocabulary is small and general so it works
   on software written next month; the register is what the person and the onboarding build,
   so Sea-Star never guesses a name to recognise a friend.
5. **The register matches by identity, not by label.** An entry may be a display name, a
   bundle path, or the folder name. Found by getting this wrong: the register said *"Unsloth
   Studio"* while the bundle calls itself *"Unsloth"*, and a live endpoint on port 8888 was
   silently lost. Any of the three is enough.
6. **Onboarding is where the residents get named, once.** The scan proposes a candidate with
   its evidence shown — what it saw and where — and asks what it is. The answer is remembered
   by bundle identity; the question is never asked twice. The place a name would have gone in
   the old hardcoded list is now a place the person writes once.

### Consequences

- `doctor` (and the bridge JSON) gains `listening`, `model_like` and `outbound`. Additive, so
  an older app ignores them.
- On this machine the read immediately found something no part of Sea-Star could see before:
  **Unsloth Studio serving a model on `127.0.0.1:8888`**, plus `oMLX` on 8009, `Atomic Chat` on
  1337 and DeepSeek Harness on 19387 — every one attributed to its app.
- It also answers the founder's *"keeping track of when APIs are being used"* honestly: a live
  outbound connection is visible, attributed, and nothing is captured.
- The `harness → inference` wire D-004 left open can now be drawn from evidence
  (`Atomic Chat/data/local-api-server.json` names port 1337; the socket table confirms the
  process holding it).
- **`KNOWN_HARNESS_APPS` is demoted to a seed, not a gate.** It still names common apps so a
  cold machine is not blank on first run, and it is no longer the mechanism that decides what
  exists.
- **The default `/Volumes` sweep is removed.** A mounted volume is read only when a caller
  names it: the founder's no-go rule covers his external drive, and an unconditional sweep is
  exactly the quiet visit that rule prevents.

### Open

- The register itself (the "ask once, remember" store) and the candidate-with-evidence card
  are not built yet; `recon.py` is the read they will be built on.
- Xcode and non-beta OpenCode produce no reliable fingerprint and remain the honest residue
  the register exists to cover.

### Revisit when

- The register ships: record what it stores and where, and prune `KNOWN_HARNESS_APPS` to the
  handful that genuinely help a first run.

---

## D-006 — The register: one question per thing, and only evidence may raise one

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** architecture (`register.py`, the bridge), UX flow, product values

### The problem

D-005 built the reconnaissance but left the question it implies unanswered: what happens when the
read finds something Sea-Star has never heard of? Without an answer the only options are a
hardcoded list (stale in a fortnight) or silence (invisible harnesses). Two of the founder's
seven apps — Xcode and non-beta OpenCode — produce no fingerprint at all, so no amount of
cleverness replaces asking.

### The decision

1. **The register is a store, not a scan.** `~/.seastar/register.json` holds one verdict per
   thing, written by the **engine** and never by the app, so there is exactly one writer and
   the two cannot drift into keeping separate copies of the same decision. The cockpit asks
   and sends the answer down; it does not remember anything itself.
2. **Identity is the bundle id, or the path — never the display name.** A label is chosen by
   somebody else and changes between versions. This is not theoretical: matching on the label
   already cost a live endpoint once ("Unsloth Studio" vs the bundle's "Unsloth").
3. **A dismissal is a decision.** "Not a harness" is stored as a verdict, not as an absence,
   so the cockpit stops proposing the same noise every launch. It can be undone — a verdict
   the person cannot revise is a trap.
4. **Only evidence may raise a candidate.** Each candidate carries the observed facts that
   produced it, and the cockpit shows the evidence above the buttons. A candidate without
   evidence would be a demand for trust.
5. **Vocabulary must qualify on a *protocol* word.** Testing forced this. Brand names are
   worthless alone: Firefox, DuckDuckGo and ProtonVPN all "name OpenAI" because browsers ship
   lists of domains they block or trust. Requiring `mcpServers` or `modelcontextprotocol`
   reduced twelve hits to five, all genuinely agentic, with no false positives — and it caught
   **CC Switch**, an app this build's seed table has never heard of.
6. **"Installed" is not evidence.** Offering all 31 installed apps produced 31 questions, which
   is noise rather than onboarding. Only the seed table's apps are offered, with a suggested
   name so a first run is one click each. Every other app stays visible in the report — it is
   simply not accused of being a harness on no grounds. Nothing is hidden; ranking is not
   hiding.
7. **The seed table is a hint, never a gate.** `KNOWN_HARNESS_APPS` now supplies a suggested
   name and a first-run starting point. It decides nothing about what exists.

### Consequences

- New commands: `sea-star harnesses [--scan] [--workspace PATH]`, `adopt`, `dismiss`, `forget`.
  `--scan` turns on the slow bundle-vocabulary read; it is off by default because a cockpit
  poll has to stay quick.
- The bridge carries `candidates`; the cockpit shows a `New on this machine` section with each
  candidate's evidence, an editable pre-filled name, and the two answers.
- On this machine the first run offers 17 candidates, including CC Switch and every endpoint
  the reconnaissance found.
- The four answers a person can give about a thing are now: a harness, not a harness,
  not decided yet, and forgotten (asked again).

### Open

- The workspace family (`.trae/`, `AGENTS.md`) needs a project path the cockpit does not
  currently supply; the CLI takes `--workspace` today. It is the only family that proves *use*,
  so the cockpit should pass the vault, or the project, in a later pass.
- `mcp_configs` records only that an app keeps a tool list, never the tools inside it. Naming
  them would be genuinely useful (the symmetry clause) and is a separate decision about reading
  another app's configuration.

### Revisit when

- The workspace family is wired into the cockpit, and when the register has been in use long
  enough to see whether the seed table can shrink to nothing.

---

## D-007 — An inbuilt model server belongs to its app, and the dependency is stated. MCP cannot discover inference; the OpenAI schema can.

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** architecture (`recon.machine_summary`, the bridge, the MCP surface), product values, UX flow
- **Founder input:** *"some of them like to have inbuilt servers for inference. So how do we deal with
  that? … That's got to be an MCP issue, I would imagine … MCPs couldn't just ask for one to know
  what's going on in whatever harness it's dealing with?"*

### The problem

A harness with an inbuilt inference server is two things in one process: the app a person uses, and
the endpoint models come from. The ontology (D-001/D-004) draws those as separate rows, which is
right, but it leaves a fact unstated and it is the one that bites: **the endpoint dies when the app
quits.** Measured on this machine, the problem is total rather than occasional — **all four**
loopback model servers belong to an app, and Sea-Star's own configured brain is one of them
(`127.0.0.1:1337`, inside Atomic Chat). Quitting a chat app would stop Sea-Star thinking, and
nothing in the product said so.

### The decision

1. **The owning app is the endpoint's identity.** The reconnaissance already resolves a socket to
   its app through the process tree, so the relationship is read, never assumed. An endpoint with
   an owner is *inbuilt*; one without stands alone. Every readout that names an endpoint names its
   owner.
2. **The dependency is stated where it matters.** When the endpoint is the one Sea-Star is using,
   the readout says so in plain words: *"Runs inside Atomic Chat. Careful: stops when Atomic Chat
   quits — Sea-Star's own model lives here."* A cockpit that knows this and does not say it is
   withholding the most actionable fact on the screen.
3. **MCP is not the discovery channel for inference, and should not be made into one.** MCP has no
   schema for "which model servers do I run". Its handshake identifies *who* is attached; its
   tools and resources expose *what that server chooses to offer*. Inventing a tool for this would
   require every harness to implement it — the same trap as a list of app names, one layer up.
4. **The protocol that exists for this is the OpenAI-compatible one.** `GET /v1/models` is how
   every local runtime this project supports says what it serves; that is why Sea-Star already
   speaks it. Inference discovery belongs to `config.probe_*`, and *ownership* discovery belongs to
   `recon`, which reads the socket and the process tree.
5. **The symmetry clause is honoured in the other direction.** Sea-Star now exposes
   `machine_report` over MCP: an attached harness can ask what is running, which servers are
   inbuilt, and who owns them — the same facts the cockpit draws, from one shared function
   (`recon.machine_summary`), so the two can never describe the machine differently. Read-only,
   local, nothing retained.

### Consequences

- `recon.machine_summary()` is the single rendering of the machine for callers that cannot draw
  it; `register.recognised_names()` is the single definition of what this machine recognises, now
  used by both the cockpit's report and the MCP answer. Before this, the bridge assembled that set
  inline and the MCP surface would have needed a second copy.
- The bridge gains `model_like[].app_name` / `app_path`; the app decodes them and adds
  `Runs inside <app>` plus the warning on the endpoint it is currently using.
- `machine_report` joins the MCP tool surface, so a host that cannot read sockets is no longer
  blind to where its models come from.
- A fresh machine with an empty register now recognises the seed table's apps and any attached
  host, so the MCP answer is useful on first run rather than naming only the endpoints that happen
  to carry runtime vocabulary.

### Open

- An inbuilt server may be **unauthenticated** and reachable by any local process. Sea-Star
  borrowing one is the person's own machine and their own choice, but whether the cockpit should
  note "this endpoint accepts anything on this machine" is a separate decision, and a privacy one.
- Nothing yet distinguishes an app that *intends* to serve other tools from one whose server is
  private to itself. It may never be knowable, and it may not matter.

### Revisit when

- A harness exposes its endpoints over MCP of its own accord, or the unauthenticated-endpoint
  question is raised by the founder.

---

## D-008 — The behaviour ledger: one app with no stake reports what every interested app is doing

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** product values (the app's reason to exist), architecture (`recon`), UX flow
- **Founder input:** *"many of these harnesses can obviously pull in outside servers, but they also
  make money off using their own — and that's both APIs and downloaded models — but they will run
  for convenience … every harness right now is dog eat dog, they're all out to compete and win …
  if it can let someone on their machine know everything that's going on with the various — I won't
  say predatory but extremely feisty — harnesses, then we're onto something that will actually
  really get traction."*

### The problem

Every harness on a modern machine is an interested party. It ships its own model server, it
resells its own cloud, it downloads its own weights, and it has no reason to tell a person which
one it is using at any moment. The person's machine is a contested space and nobody publishes the
score. This is the first product reason for Sea-Star that is not a *privacy* reason: not "nothing
leaves the house," but "somebody finally says what is going on in the house."

### The decision

Sea-Star keeps a **behaviour ledger**: one row per app, containing only observations.

- **What it serves** — the loopback model servers it is answering on.
- **Whether it is using its own server** — read from a live connection from that app to that port.
- **What it reaches for** — the hosts outside this machine it is connected to right now.
- **The flagged case** — it ships a server, is not using it, and is reaching outside anyway.

Three rules make it trustworthy rather than merely pointed:

1. **No motive is ever attributed.** There is no field for intent, because intent was not
   observed. The flagged line states its two observations — *"inbuilt server on 8009, reaching
   outside instead"* — and stops. An app may have an excellent reason; the person judges.
2. **"Not using them" is never said.** A server may be in use by somebody else — Sea-Star itself,
   for instance. Claiming neglect would be a guess dressed as an observation, and the first
   version of this code said exactly that and was wrong.
3. **A stranger is a candidate, not a row.** An app that serves nothing and is not recognised is
   excluded from the ledger and arrives through the register instead (D-006). A browser's ordinary
   traffic must not read as though it were a harness — tested, because the first version put
   Chrome in the same list as oMLX.

### Consequences

- `recon.harness_behaviour()` is the one scoped filter; `ledger_lines()`, the bridge's `behaviour`
  array and the MCP answer all read from it, so the sentences cannot disagree with the rows.
- The bridge gains `behaviour`; the cockpit gains a `What each app is doing` band, and the
  flagged row wears the warning colour.
- On this machine the ledger reads: Atomic Chat serves 1337; oMLX serves 8009 and is using it;
  Unsloth serves 8888; DeepSeek Harness serves 19387, is using it, and is reaching 2 hosts
  outside. Four harnesses, four inbuilt servers, one of them also in the cloud.
- **A bug this shape caught immediately:** the ledger first shipped nested inside the `vault`
  object, because the insertion anchor matched the vault's own `candidates` key. Nothing read it
  and nothing failed; only reading the JSON found it. There is now a test asserting `behaviour` is
  top-level and *not* inside the vault.

### Open

- Nothing yet says *whether* an app's outbound traffic is model traffic or ordinary telemetry.
  Distinguishing them would need to read connection contents, which this project does not do.
- The ledger is per-session, not historical. "Which app reached outside last Tuesday" needs a
  record, and a record is exactly what the no-background-monitoring rule makes a founder decision.

### Revisit when

- The founder wants history rather than a live reading, or wants the ledger to name *what* an
  app is reaching for beyond the host.

---

## D-009 — Traffic never raises a question; browsers and OS components are barred by declared role

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** architecture (`register.discover`, `recon`), product values, UX flow
- **Supersedes:** part of D-006. D-006 listed "connected to N hosts outside this machine" as one of
  the evidence families that may raise a candidate. That was wrong, and the screenshot showed why.
- **Founder input:** *"as soon as you mentioned Chrome … oh shit, that's right … it's gonna get
  really messy in that area … let's cut chrome and browsers right out of it because they're always
  discretionary … that market … generally aren't a target market … that's just a minefield cluster
  fuck that we don't want to deal with. So let's work out a strategy to avoid that fucking with us."*

### The problem

The register proposed **Google Chrome** as a harness, on the evidence that it was connected to four
hosts. So did the ledger, before scoping. The root cause was a rule, not a list: **outbound traffic
was allowed to raise a candidate on its own**, and almost every networked app reaches outside. That
one rule would have proposed browsers, messengers, updaters, VPNs and sync clients on a machine with
more software on it — burying the ten real harnesses in noise, on the exact screen whose promise is
"this is what is on your machine".

### The decision

1. **Traffic never raises a question.** Outbound connections are applied *after* the other families
   as enrichment: they tell you something about a thing already worth asking about, and they never
   create one. This is the correction that matters — the rest is consequences.
2. **A declared web client is barred, by role and never by name.** Every browser must claim
   `http`/`https` in its own `Info.plist` to be offered as a handler, so the operating system
   already maintains the browser list and Sea-Star reads it rather than keeping one. Verified on
   this machine: Chrome, Firefox, DuckDuckGo and Safari all declare it; Atomic Chat, Trae, Unsloth,
   oMLX, Xcode and CC Switch declare only their own scheme. A browser written next year is barred on
   the day it ships, with no code change.
3. **An OS component is barred.** Anything under `/System/` is the operating system doing its job —
   ControlCenter and its AirPlay ports were the second piece of noise on the same screen.
4. **One question per app.** A finding inside an app's own support folder is attached to that app
   rather than asked about separately. Atomic Chat and TRAE SOLO each appeared twice (as an app and
   as the folder holding its tool list); both now appear once, with both pieces of evidence.
5. **Classify only the known knowns, and say so.** Harnesses; harnesses with inboard servers;
   servers; and how tools consume inference *at the moment*. The bar for *asking a question* is
   deliberately high. The bar for *reporting* stays at zero: every app, port and connection remains
   in `listening` and `outbound`, unfiltered. Nothing is hidden by this decision — it only stops
   things being accused.

### Consequences

- The register's first run went from 17 candidates to **13**, all of them genuine: ten GUI harnesses
  and three CLI agent state directories. No Chrome, no ControlCenter, no duplicates.
- The exclusions live in `harnesses.py` (`is_web_client`, `is_system_component`) and are applied in
  **both** the register and the ledger, including inside the unfiltered `harness_ledger`, so there
  is no route by which a browser becomes a harness.
- **A known cost, accepted deliberately:** an AI assistant living *inside* a browser — a Gemini or
  Copilot side panel — is barred by the role rule even though it is arguably a harness. The founder
  named that market as out of scope and discretionary, so barred is the right default. If it ever
  matters, it needs a rule that distinguishes an assistant from a browser, and that is not obvious.
- Verified live during this work: **Atomic Chat quit while the code was being changed**, its port
  1337 disappeared with it, and Sea-Star re-resolved its own inference to oMLX on 8009 without
  intervention. D-007 predicted exactly this; the machine performed the experiment.

### Revisit when

- An in-browser agent assistant is wanted on the graph, or a non-browser app is found to declare
  `http`/`https` and be wrongly barred.

---

## D-010 — A port is not a server: only an answered probe may be stated as serving

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** architecture (`recon`, the bridge), product values
- **Corrects:** D-008's ledger, which reported a suspected port as a serving one.
- **Founder input:** *"I would've thought that generally looking at ports would've been one
  of our best sort of indicators of what's going on … I'm just talking from intuition."* His
  intuition was right, and it also showed where the ledger had gone wrong.

### The problem

The ledger said **"Unsloth: serves models on 8888"**. It does not. Port 8888 is owned by Unsloth,
on loopback, and carries runtime vocabulary — every signal this project had. Then an
OpenAI-compatible probe was pointed at it and **it did not answer**. On the same machine, three of
the four ports the ledger called model servers had never been asked, and only one (oMLX on 8009)
actually served.

The cause was a category error, not a bug: the vocabulary rule is a *hint* about a port, and it was
being reported as a *fact* about a server. The same error reached the flagged case — DeepSeek
Harness appeared as "inbuilt server on 19387, reaching outside instead", an accusation resting on a
port that serves its own user interface and no models at all. A ledger that accuses an app on the
strength of a guess is worth nothing, which is the whole point of the ledger.

### The decision

1. **Proved and suspected are different fields.** ``HarnessBehaviour`` carries ``serves`` (ports
   that answered an OpenAI-compatible probe) and ``listening`` (ports that look like servers), and
   ``unconfirmed`` is the difference. The bridge and the panel carry both; the copy distinguishes
   them: *"serves models on 8009"* versus *"listening on 8888, not answering as a model server"*.
2. **Only proof may be stated as serving.** The reading, the ledger and the MCP answer all use the
   same rule, because they share one function.
3. **The flagged case requires a proved server.** An app cannot be accused of neglecting a server
   that never answered — ``owns_idle_server`` is built on ``serves``, not ``listening``. This
   removes a live false accusation rather than a hypothetical one.
4. **Probing stays in `config`, never in `recon`.** ``recon`` reads process and socket tables and
   does not speak HTTP; a read of the machine must not open a connection to answer a question about
   connections. The answered ports are threaded in by the caller, which is why they are a parameter
   and not a lookup.
5. **Ports remain the best indicator, and are not sufficient alone.** The founder's intuition holds:
   a port is behaviour an app cannot talk its way out of, and it is the only signal that survives an
   app saying nothing about itself. But a port proves *presence*, and only a probe proves
   *capability*. The ledger needs both, and must keep saying which is which.

### Consequences

- The ledger now reads honestly on this machine: `oMLX: serves models on 8009; and is using them`,
  `Unsloth: listening on 8888, not answering as a model server`, `DeepSeek Harness: listening on
  19387, not answering as a model server; reaching 2 host(s) outside this machine`.
- `model_like` entries carry ``answering``, and the app's `ModelLikeInfo.isProved` defaults to
  *unproved* for an older engine rather than crediting it with an answer it never gave.
- **A bug found by the same change:** the MCP tool called a synchronous helper that used
  ``asyncio.run`` from inside the server's own running event loop, and failed at the first call.
  The tool now awaits the probe directly. Recorded because a "convenience" sync wrapper around an
  async system is exactly the kind of thing that works in a test and dies in the product.

### Open

- Two ports on this machine are suspected and unproven. Whether Sea-Star should *try* to make them
  answer — by asking with a model list request the app might accept on another path — is untested
  and may be pointless; the honest reading is available now, so there is no pressure to.

### Revisit when

- A runtime answers a probe on a path other than ``/v1/models``, or a suspected port is confirmed
  serving by a second method.
