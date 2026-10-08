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

---

## D-011 — Ship via Developer ID and a notarised DMG; the Release configuration refuses to build without a real signature

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** architecture (`macapp/project.yml`, `script/release.sh`), distribution, product values
- **Founder input:** *"I really have to apologise, I totally forgot about the notarisation Apple side of
  it. So of course we're not gonna deliver anything tonight … but at least I'd like to get to the
  point of looking good, to get it close — something ready to go to Apple."*

### The problem

The app had one build configuration, with signing switched off entirely
(`CODE_SIGNING_ALLOWED: NO`, `ENABLE_HARDENED_RUNTIME: NO`, ad-hoc identity). That
is correct for development and useless for shipping, and the two were the same
setting. Nothing about the app said, anywhere, that it could not be handed to a
person — and there is no signing identity on this machine at all, so notarisation
is not a configuration detail to be discovered at upload time.

### The decision

1. **Two configurations, because building for yourself and building for strangers are
   different acts.** Debug stays ad-hoc and unsigned so anyone can build without an
   Apple account. Release requires the hardened runtime and a Developer ID.
2. **The Release configuration fails rather than degrades.** Notarisation requires the
   hardened runtime; the hardened runtime is meaningless without a real signature. A
   Release build that silently fell back to ad-hoc would produce a DMG that Gatekeeper
   refuses on someone else's Mac, and the failure would arrive as a support message
   instead of a build error. Failing the build is the honest place for it.
3. **No account identifier is committed.** The identity is fixed in the project; the
   Team ID is supplied by `script/release.sh` from the environment.
4. **Developer ID and a notarised DMG, downloaded from GitHub — not the Mac App Store.**
   App Store apps must be sandboxed, and Sea-Star reads an Obsidian vault from an
   arbitrary folder while spawning a Python engine as a child process. Both are exactly
   what the sandbox prevents. Sandboxing is a rewrite of how the app reaches the vault,
   not a signing task, so the App Store is recorded as not available to this design
   rather than left as an open possibility.
5. **Every gate the script can check, it checks first** — certificate, Team ID, notary
   credential — and it asks Gatekeeper for its own verdict at the end with `spctl`,
   because every step above can report success while Gatekeeper still refuses.
6. **`--dry-run` exists so the pipeline can be proven without an account.** It builds,
   packages and labels the result as unsigned and not for distribution.

### Consequences

- `script/release.sh --dry-run` was run and completes: Release builds, the signature is
  verified, a 1.7 MB DMG is produced at `dist/Sea-Star-0.1.0.dmg`, and the run stops
  before notarisation stating plainly that Gatekeeper would refuse it elsewhere.
- Run without `--dry-run`, it stops at the first gate with the exact steps to fix it —
  verified, since no certificate exists on this machine.
- `docs/ship.md` records the one-time setup, the two routes, and the remaining gap.

### Open — and this is the honest headline

**The engine is not inside the app bundle.** The DMG contains the menu-bar app and
nothing else; on this machine the app finds the repository and `sea-star` on `PATH`,
and on a stranger's Mac it would find nothing. A notarised DMG is therefore *not yet
worth distributing*, and no amount of signing fixes it. Closing it means vendoring the
engine into `Contents/Resources/engine` and pointing `EngineCommand.resolve()` at the
bundle first, and ideally bundling a relocatable Python so the app is self-contained.
The release script says this on every run rather than letting it surface after
notarisation, when the DMG looks finished and is not.

Also open: a shipping decision the founder should make knowingly — the deployment
target is **macOS 26.0**, so anyone on an earlier Mac cannot run it at all.

### Revisit when

- The engine is bundled: then flipping the repository public and attaching a notarised
  DMG to a GitHub release is the last step, and this entry should be updated with the
  first notarised version number.

---

## D-012 — Three surfaces, one job each: the cockpit is a reading, onboarding is a window, Settings wears the house style

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** UX flow (a new window exists), architecture (view layer), product values
- **Corrects:** part of D-005/D-006/D-008 as implemented — the register, the ledger and the
  harness-visibility list were rendered *inside* the cockpit popover, which was never their place.
- **Founder input:** *"that 'what each app is doing' and 'what's idle' and 'new on this machine',
  all that shit is meant to be just part of an onboarding window, not part of the standard
  mechanics of the app … the idle stuff, that was options for whether you want to see it on the
  graph or not … there's no selector up the top as there was before … it is completely fucked up
  right now."*

### The problem

Three additions in one day were each appended to the cockpit's list reading, because the app had
only two surfaces (the popover and the Settings window) and no onboarding surface at all. The
popover has a width cap and *no height cap* — the one height clamp that existed was applied only to
the graph's pool — so list mode grew past the display, macOS kept the popover on screen by moving
it up, and the header with the graph/text switch went above the top edge of the screen. The graph
was one click away and the click was off-screen. The idle list, whose buttons say "Float on the
graph", was sitting in the text reading where it could change nothing visible. The ledger and the
register duplicated and contradicted each other four rows apart.

### The decision

1. **The cockpit is a reading, and only a reading.** List mode is the four rows and the
   working-now band. Graph mode is the starfield with the float/take-off list directly beneath it,
   because that list changes what the graph shows and belongs next to it.
2. **Onboarding is its own window.** Home for the ledger, the register (all of it, unfolded — the
   window *is* the backlog) and the graph's cast list. It opens once on first launch and is
   reachable afterwards from the menu bar ("Set up Sea-Star…") and from Settings. Never inside the
   popover.
3. **A hard height ceiling with one scroll region.** The header, logs and controls sit outside the
   scroll; the middle scrolls when it must. The panel can no longer push its own header off the
   screen — the failure is impossible rather than merely repaired.
4. **Settings wears the house style.** The generic grouped form is replaced by the cockpit's own
   language: the canvas, the ink, the accent bars, the mono headings and the plain word buttons, so
   the three surfaces read as one app.
5. **Two detail lines that lied are fixed.** The Vault card's second line was the literal word
   "Notes" (a label where the count belonged); the Harness card borrowed another app's rung
   ("Installed, not running") while its own value said "None attached". It now says, plainly, that
   no app is driving Sea-Star.

### Consequences

- New file `OnboardingView.swift`; `AppDelegate` gains an onboarding window, a menu item and the
  one-shot first-run logic (`SeaStar.onboardingShown`, marked only after the window is actually up).
- `CockpitPopoverView` loses the ledger, register and idle sections; the visibility list moves into
  graph mode as a shared `HarnessVisibilityList`.
- **A dormant bug this pass flushed out:** the popover open/close flag
  (`SeaStar.cockpitOpen`) was *never being set*, because the delegate methods used the old
  `popoverDidShow(_ popover: NSPopover)` signature while the macOS 26 SDK's `NSPopoverDelegate`
  takes a `Notification`. It compiled silently and never fired, so the starfield's "open" state was
  permanently false. Fixed by correcting the signature, and now verified end to end (flag reads 1
  while open, 0 after closing).
- Measured on this machine with the cap in place: list mode 386×574, graph mode 626×786 — both
  within the display, header reachable in both.

### Open

- The onboarding window's *visual* pass has not happened (the session's model cannot see the
  screen); sizes and behaviour are verified through the window system, not by eye.
- The first-run moment is a window on launch; whether it should also present itself when the
  cockpit first opens to graph mode is a small follow-up judgement call.

### Revisit when

- The founder has seen the restructured surfaces and confirms the register feels like a desk to
  clear rather than a reading.

---

## D-013 — The cascade is the spine: vault → harness → agent → inference, rendered by every surface from one rule

- **Date:** 2026-10-02
- **Status:** Accepted
- **Affects:** UX flow, architecture (the agent→endpoint derivation), the MCP surface
- **Founder input:** *"when the agent is selected and then you click inference, does it actually show
  the inference for that particular agent — and when harness is displayed, does it pick the agents
  for that particular harness? … as long as it cascades down from harness, then you pick the
  harness, then you pick the agent, and then you pick the inference that agent is on and know where
  it's at — whereas on our graph we can immediately see that graphically as well. This is the whole
  concept of the app."*

### The problem

The concept had always been the spine and the graph had always drawn it — agent → its model → the
endpoint serving it. The text panel did not. Selecting an agent changed only the agent row itself;
the Inference row kept showing whatever the endpoint was serving, so the two readings of the same
request path disagreed, and a person picking Patchdog could not see that Patchdog lives on oMLX.

### The decision

1. **One cascade, one rule, three surfaces.** The placement of an agent — its model, and the
   endpoint that serves it — is derived by one rule with three honest cases: the model is *served
   by* a running endpoint; the model *names* a provider whose endpoint is up but not serving it;
   or *nothing* answers to it. The Swift panel (`ServerController.placement(of:)`), the Python MCP
   answer (`agents.placement`), and the graph's existing wiring all express the same three cases in
   the same sentences.
2. **The text panel speaks the last hop.** When an agent is selected, the Inference row shows the
   sentence beneath it: "Runs on X — served by Y", or the honest alternative. The agent row's help
   already names whose roster it is (Osaurus today), which is the harness-scoping half of the
   cascade said honestly rather than invented.
3. **A host hears the whole cascade.** `machine_report` gains "Agents and where they run": every
   agent, its model, and its placement. A harness attached over MCP asking "where does Patchdog
   run?" gets the same sentence a person gets from the rows — the utility the founder named as
   flowing on from the concept.

### Consequences

- On this machine the MCP answer now reads, for the founder's own roster:
  `Patchdog: Runs on omlx/KAT-Coder… — omlx is up, but not serving it.` — the distinction between
  "offered" and "built for" that a flattened answer would have lied about in one direction or the
  other.
- 3 new Swift tests, 4 new Python tests pin the three cases. 79 Swift, 153 Python, ruff clean.
- The harness→agent scoping half remains deliberately unbuilt: the engine reads one roster
  (Osaurus) and says so. Reading every harness's own roster is engine work and stays on the list.

### Open

- Reading each harness's own roster, so the Agent row genuinely becomes "the crew of the attached
  harness" rather than one named source.

### Revisit when

- A second roster source exists in the engine: then `placement` is computed per harness and the
  agent row follows the Harness row.

---

## D-014 — The harness list is a drawer: the graph keeps its room, and the pool gives way

**Date:** 2026-10-06

**Context.** The latent-harness list sat permanently under the starfield. The founder's read was
that the listing *belongs to the graph* rather than beside it — a graph you are reading should not
be half-covered by its own legend — and he asked for the drawer his own Vibette build already
uses: the slide-down tray, a nod to QuickTime 4's drawer, with an Aqua grip at the top of what it
reveals.

**Decision.** The list moves into a **drawer at the foot of the graph**, opened by one centred
control and closed by that control or by the grip. Two things are kept from the reference, both of
them native: the **attachment** (the tray grows out of the panel's lower edge; it is not a second
window and not a popover) and the **motion** (a connected slide that tracks the opening edge). No
`NSDrawer`, no deprecated API, no Aqua bitmap.

**The height rule.** The cockpit's height is capped (D-012), so a tray that simply grew would open
below the fold — the first build did exactly that, and cut the last row in half. **An open drawer
is paid for out of the pool:** the graph gives way by the tray's height, so the panel's total height
is unchanged and the whole drawer is on screen. "The panel extends" has to be read against a screen
that will not get any taller, so the pool is what yields.

**Consequences.**

- Graph mode opens shorter and quieter: closed, the drawer is one word at its foot; open, it holds
  the whole roster (8 rows on this machine) with no row cut in half.
- The row itself is untouched — `HarnessVisibilityList` is shared with the onboarding window, so one
  row and one wording are read wherever the list appears.
- An extreme roster still scrolls *inside* the drawer (244pt cap), so the controls can never be
  pushed off the display.
- 83 Swift tests, 158 Python tests, ruff clean; the drawer was driven live over Accessibility
  (`AXPress` — synthetic clicks are not delivered to this process) and screenshotted in both states.

**Open.** Whether the drawer should remember its open state between launches. It is session-only
today, which keeps the cockpit opening uncluttered.

---

## D-015 — A harness is found by more than its bundle, and an endpoint is probed wherever it listens

**Date:** 2026-10-06

**Context.** The founder's test: Atomic Chat open with an Apple foundation model loaded, MCP-linked
to OpenCode, which was also open — he hit Refresh and *none of it came up*. Two separate gaps were
behind that, and they were the same mistake in two places: **Sea-Star was looking only where it had
already decided to look.**

1. `running_app_paths()` read the process table for `.app` bundles. OpenCode was running as a bare
   CLI binary, so it could not appear as running at all — while the *installed* OpenCode desktop app
   showed as latent. A harness that was demonstrably open read as absent.
2. `probe_runtimes()` swept a fixed port list. Atomic Chat's Apple foundation server answers on
   **3355**, which is not on that list. Reconnaissance *saw the port listening* and attributed it to
   Atomic Chat; Sea-Star never asked it whether it served models. A live endpoint Sea-Star could
   already see was never spoken to.

**Decision.**

- A harness may be found **by bundle id, by CLI command name, or by nothing at all** — and a missing
  name stays an *additive hint* in the foundation's sense: rename the binary and it drops off this
  list, while every other family still finds it. A running CLI harness carries the `running` rung,
  because running is what was observed; a stopped one is reported as nothing, because for a bare
  binary there is no install to have found.
- **An endpoint is probed wherever it is observed to listen**, not only where the sweep list expects
  it. The ports come from `listening_services()` and are threaded in by the caller, preserving the
  split D-010 drew: `config` asks a port, `recon` surveys the machine, and neither does the other's
  job.

**Consequences.** `sea-star doctor` now reads `Inference: remote (1337), omlx (8009), apple (3355)`
and `Running: DeepSeek Harness, Xcode, OpenCode (up, not answering yet)`, and OpenCode no longer
appears twice — a running CLI harness stands in for its installed desktop sibling.

**Open.** The endpoint on 1337 names itself `remote` (its own `owned_by`), which is what the note
beside the pool now says: *"remote is connected"*. That is not wrong, but the owning app is already
known — the same card reads "Runs inside Atomic Chat" — so a better label exists. It wants the name
to come from that attribution rather than from the server's own generic word, and it was
deliberately not changed in the same breath as the discovery fix. Note that `remote` cannot simply
join `GENERIC_OWNERS`: the fallback for port 1337 is the *port's* known harness, which would
mislabel Atomic Chat as Osaurus.

---

## D-016 — The header is a mode switch and Settings; every other choice lives in its own reading

**Date:** 2026-10-06

**Context.** The founder looked at the header and counted: *"there's too many of them … there's
four buttons up there between text and graph"* — the mode pair, the depth-or-layout pair, and the
gear, five controls in a bar that also has to hold the app's own name. In the narrow text reading
that bar was squeezed until **"Sea-Star" rendered as "Sea-" / "Star"** and the subtitle wrapped
under it. The header was carrying a control for a reading the person was not in.

**Decision.** The header keeps **one pair of symbols — the mode switch — and Settings**, and
nothing else. Each secondary choice moves into the **drawer at the foot of the reading it affects**
(D-014), which is where the QuickTime ledge earned its keep:

- the graph's drawer carries **Depth** above the harness roster it already held;
- the text reading's drawer carries **Layout**.

The drawer therefore stops being "the harness roster's home" and becomes **the reading's own
ledge** — a control belongs there when it is only meaningful inside that reading.

**Consequences.**

- Five controls become three, and the name is pinned to one line (`.lineLimit(1)` + `.fixedSize()`)
  so it can never break again in the narrow column.
- The drawer is generic (`CockpitTray<Content>`) and `TrayChoiceRow` gives any drawer a labelled row
  of exclusive choices; `HarnessTray.swift` is replaced by `CockpitTray.swift`.
- The pool-gives-way height rule (D-014) still applies in graph mode only, since the text reading
  already hugs its content.
- Spec §8.7 amended; the stale "Both" comparisons it still described were removed in the same pass,
  having been retired by D-003.
- 83 Swift tests, 162 Python tests, ruff clean; both readings screenshotted with the drawer open.

**Open.** Whether the drawer should remember its open state between launches, and whether the two
drawers should share one open state (they currently do — `isTrayOpen` is the popover's).

---

## D-017 — Sea-Star is a node in the pool, and its wires are what light up

- **Date:** 2026-10-06
- **Status:** Accepted
- **Affects:** UX flow, product values (what the graph is allowed to claim)
- **Founder input:** *"I connected them to see if anything actually happens in the graph, and it
  didn't … even without 3-D we do want everything in there once it actually is live to connect to
  the appropriate nodes."* He had already said **yes** to the earlier proposal that Sea-Star
  become a `.core` node at the centre, with the vault staying an ordinary ring node.

### The problem

The wiring was **found but not drawable**. The engine saw everything — `sea-star doctor` at the
moment of the complaint read:

```
Inference: remote (http://127.0.0.1:1337/v1), omlx (http://127.0.0.1:8009/v1),
           apple (http://127.0.0.1:3412/v1)
Serving:   DeepSeek Harness (19387), oMLX (8009), Atomic Chat (1337), Atomic Chat (3412)
Connected: Atomic Chat
Running:   DeepSeek Harness, Xcode, OpenCode (up, not answering yet)
```

and the app the founder was looking at **was** the current build (binary and launch time both
19:27). So this was a drawing failure, and it had three causes, all of them rules rather than
bugs:

1. **There was nothing in the middle to connect to.** `GraphModel.centre` was `.origin` and the
   majors ringed it, so the centre of the pool held a *decorative outline*. A picture cannot carry
   an edge: "everything connects to Sea-Star" was a claim the graph had no way to draw, and a wire
   with nothing at its end is not a wire.
2. **The flat pool drew exactly one wire** — from the vault to the endpoint currently being read —
   and only ever that one. Connecting an app to Sea-Star therefore changed a *node* and never a
   *wire*: a new star appeared with nothing joining it to anything, and the picture sat still while
   the machine changed underneath it.
3. **A harness was wired to an endpoint only when the endpoint's name matched the app's.** Atomic
   Chat's inbuilt server answers as `remote`, which is nobody's name, so Atomic Chat was never
   joined to `1337` or to the Apple foundation server on `3412` — even though the engine had
   already recorded the port's owner (`listening[].app_name`), and `ServerController.bundledOwner`
   was already reading it for the card.

### The decision

Four rules, and the fourth is the one that took two sessions to reach:

1. **A sixth kind, `.core`.** One node, `id: "seastar"`, at `.origin` in **both** `GraphModel.layout`
   and `GraphSpace3D.positions()` — the two bodies are two drawings of one arrangement and may not
   disagree about the middle. It is **excluded from `majors`**: a major's place is a point on the
   ring, and counting the core would both steal a point from the star and put Sea-Star in orbit
   around itself.
2. **Sea-Star is never `isLive`.** It is the observer, and nothing on this machine can probe the
   thing doing the probing; a heartbeat here would be the one fact the graph cannot support. Its
   *edges* are what light up — a live edge is the crawl, green-and-orange while a live thing is on
   it and blue-white wiring when it is merely a stated binding.
3. **What it wires to, and nothing more:** the vault it lives in, the apps that drive it over stdio
   (`attachedHarnesses` — the engine has their process records, so that is proof rather than
   presence), and the one endpoint it is reading models through. *Not* every endpoint that happens
   to be up, and *not* every harness app on the disk: "connected" has to mean something the other
   end is doing with Sea-Star.
4. **Port ownership is a connection.** An app whose own process holds a model-server port is wired
   to that server, whether or not it is attached, because the engine observed the socket. This is
   reversible (`ServerController.endpoints(ownedBy:)`) and it is what finally draws
   `Atomic Chat → 1337` and `Atomic Chat → 3412`, and — on a machine where a chat app serves an
   on-device model — `Atomic Chat → apple`. Only endpoints that also answer as model servers are
   ever returned, so a port that merely looked like one is never claimed.

The **vault is not displaced or demoted**. It is a ring point today and stays one; this is additive.
The cascade (`vault → harness → agent → inference`) is untouched — it is a drawing that changed,
not a rule.

### The consequences

- The flat pool now draws **every binding between two things on the ring, plus every binding
  Sea-Star has** (`EntityGraphModel.standingEdges`). A model's spokes to the endpoints offering it,
  and an agent's spokes to its model, are deliberately **held back for the focus reading**: drawn
  all at once they turn a dozen nodes into a bag of string, which is the founder's own complaint
  about the 2D reading — and the reason the 3D room exists. The deep still draws every edge.
- The deep colours a wire by the same `isLive` facts the flat pool uses (`GraphScenePlan.isLive`),
  so flying between the two readings cannot change which connections look live.
- Sea-Star is drawn **larger than the vault** (`Kind.core.scale = 1.18`): the founder asked for "an
  actual big one hanging in the middle", and a hub smaller than the things wired into it reads as
  one more node with an unusual address.
- New palette entry `Palette.coreGlow = .mauve` — the palette's quiet structural voice, the colour
  the pool's own rays are already drawn in. Deliberately not the vault's bone, or the hub and the
  memory it lives in would read as the same kind of thing.
- `EntityGraphView.layout(in:)` becomes internal, like `nodeSize` and `hitNode`: where the pool puts
  each thing is a claim both readings and the tests have to be able to check without a window.
- **90 Swift tests in 16 suites** (7 new), **162 Python tests**, ruff clean; app rebuilt, relaunched
  and screenshotted: the hub at the middle with a lit wire to Atomic Chat, a wire to the endpoint it
  is reading through, and Atomic Chat joined to both of its own servers.

### Open

- **`OpenCode → Atomic Chat` is still not drawn**, and it is the one link of the founder's chain
  that remains missing. It is not a socket — `lsof` on 1337 shows Atomic Chat listening and nobody
  connected — but a *configured provider* in `~/.config/opencode/opencode.json`
  (`"model": "atomic/Dirk-…"`), so it can only be read from the harness's own config. This is the
  same reader recommended in D-015's Open and in the previous two handoffs, and still not built.
- **A live harness's configured provider is invisible in general**, for the same reason: nothing
  reads harness config files except the Osaurus agent roster.
- **'remote' remains a poor endpoint label** (D-015 Open) — and now there are two ports owned by
  Atomic Chat, so the port-1337 fallback that made `remote` hard to rename matters twice over.
- **oMLX's own port has an owner with no node.** `model_like` reports `oMLX` owning `8009`, but
  there is no oMLX harness node, so that ownership cannot be drawn. Showing an owner that is not in
  the pool is a question about the roster, not about the wire.
- **DeepSeek Harness's own endpoint on 19387 is not an inference node**, correctly: it *listens*
  but does not answer as a model server (`answering: false`), so `endpoints(ownedBy:)` drops it.
  A harness that serves models would need to be classified as inference by the engine first.
- **The flat pool still crowds once there are many majors** — thirteen ring points is a busy star,
  and this change adds wires to it. That is an argument for the deep, not a reason to thin the
  truth; if it needs solving, the answer is a second page of the pool, not fewer wires.

---

## D-018 — The panel's rows are dials over everything that exists, and a vague name is not a name

- **Date:** 2026-10-06
- **Status:** Accepted
- **Affects:** UX flow, product values (what a control may claim)
- **Founder input:** *"Harness right now is only showing Atomic Chat. It should have a selectable
  because it's a cockpit panel, it's a dial … it should be able to select whatever is live, or if it
  exists, it should be greyed out on the dropdown … Then selecting agent is nonfunctional as well …
  it should basically reflect in all other settings that are relevant … I'm not exactly sure what
  remote reflects to."*

### The problem

Two separate faults, found by reading the panel he was looking at:

1. **The Harness row was a fact, not a dial** — deliberately, and made so by D-001/D-004 on the
   argument that the app cannot make another app attach itself. The argument still holds, but the
   row had thrown away the *roster* with it: the machine's other eleven harness apps were nowhere in
   the panel, so "why can't I use OpenCode?" had no answer on screen.
2. **The Agent row was a dial that moved nothing.** Choosing a persona only re-said a sentence under
   the Inference row (`Runs on omlx/KAT-Coder-… — omlx is up, but not serving it`), which is
   *correct* and was invisible as a consequence, so it read as broken. Nothing else followed the
   choice, and personas that could never be honoured sat in the menu looking identical to the ones
   that could.
3. And underneath both: **`remote`**, the endpoint name. Atomic Chat's inbuilt server answers
   `owned_by: "remote"` while holding port 1337 *on this machine*, so the panel said "remote is
   answering" and the graph drew a wire from something that read like the cloud. He reasonably
   assumed it was DeepSeek Harness over the API. It is not: DeepSeek Harness's own port (19387)
   does not answer as a model server at all, and there is no local DeepSeek endpoint to wire to.

### The decision

**Three rules.**

1. **A row lists everything that exists.** An entry that cannot be honoured is shown switched off
   **with its reason**, never hidden. Hiding answers "can I use this?" with silence; showing it
   greyed answers the question the row was opened to ask. Hence a new `DialRow` (options carrying
   `isEnabled` + `reason`) beside the existing `PickerRow`, which stays for lists whose entries are
   all equally usable (vaults, models).
2. **A choice that can be honoured is a real action.** Choosing a persona that an endpoint is
   serving takes the endpoint *and* the model with it, so the rows underneath agree with the row
   just chosen. Choosing one that nothing serves moves nothing — there is nowhere to move it to,
   and its entry is switched off. Choosing the harness driving Sea-Star points the engine at the
   servers that app owns; it still does not pretend to attach a dormant app.
3. **A server that names a place does not get to name itself.** `VAGUE_OWNERS` (`remote`, `local`,
   `host`, `server`, `api`) is treated as no owner at all, and the app observed holding the socket
   is used instead. A server that names itself properly (`omlx`, `apple`) keeps its own name,
   because a product name beats the bundle that ships it. Endpoint labels carry their **port**, so
   one app serving from two ports is two distinguishable entries.

The cascade's sentence and the dial's entry are decided by **one rule** (`servingPlacement(of:)`),
so a persona can never be described as unserved while its dial entry is choosable. That also fixed a
real case: the roster qualifies its models (`omlx/qwen3-large`) while endpoints list them bare, so
an agent that *was* being served had been reading as "built for X, X is not serving it".

### The consequences

- **`remote` is gone from the panel**: the Inference row reads `Atomic Chat · 1337`, and the
  Working-now band reads "Atomic Chat is answering — serving Dirk-…". The graph draws the same
  node, so its local wires stop looking like a cloud connection.
- The Harness row shows the roster with the rung as each entry's reason — `Installed, not running`,
  `Up, not answering yet` — which is the foundation §2 degradation contract applied to a menu.
- `VAGUE_OWNERS` is deliberately **not** merged into `GENERIC_OWNERS`: dropping `remote` outright
  would send the name to the port table, and 1337's known port is Osaurus, so Atomic Chat would be
  relabelled as a different product (D-015's warning, and the test that pins it).
- `placement(of:)` now resolves through `servingPlacement`, so the agent sentence and the dial
  cannot drift apart.
- **95 Swift tests in 17 suites**, **164 Python tests**, ruff clean; app rebuilt, relaunched and
  screenshotted.

### Open

- **"Which harnesses are using this endpoint" is still unanswerable.** With oMLX selected, the
  panel cannot say who is reading from it, because nothing reads a harness's provider config.
  `~/.config/opencode/opencode.json` names `atomic/Dirk-…` — the one link of the founder's chain
  still missing, and now the blocker for the last thing he asked for on this panel. It is the same
  reader recommended in D-015, D-017 and three handoffs, and still not built.
- **Choosing a harness re-points the endpoint; it does not attach the app.** Whether the cockpit
  should go further — for example offering to *ask* a running harness to attach, over MCP — is a
  Scope question for the founder, not an implementation detail.

---

## D-019 — The two text readings are Facts and Path, and the choice lives in the header

### The problem

The panel carried two text layouts, called `Stack` and `Chain`. Both survived D-003 (which retired
only the `Both` comparison mode), so both were still reachable — but their names described *how they
were laid out* rather than *what they communicate*, which is why the founder could not tell from the
header which one was meant to be the product. The toggle itself had also migrated into the reading's
drawer (D-016), which the founder read as over-engineered for a choice with two options.

The founder's correction was specific: the fork was a *comparison* that was run up and never closed
by a decision, and the terms "stack" and "chain" were the wrong vocabulary.

### The decision

- The two readings are **Facts** and **Path**. Facts is the column you scan; Path is the journey a
  request travels (vault → harness → agent → inference). Both stay — the founder judged that Facts
  carries something Path cannot and vice versa, so this is two valid readings rather than a
  winner-take-all.
- The `PanelLayout` cases are renamed `.facts` and `.path`, but their **raw values deliberately stay
  `"stack"` and `"chain"`** so a stored preference from before the rename still resolves. The case
  names are the truth; the raw values are a migration.
- The toggle moves **out of the drawer into the header**, shown only in the list reading (it is that
  reading's layout, so it has no meaning over the graph). Two Apple SF Symbols, the active one lit,
  with the hover text carrying the label.
- The text reading's drawer is removed — layout was its only content. The graph drawer is untouched:
  it keeps Depth and the harness roster, which is its proper home.

### The consequences

- The header carries three controls again in the list reading (mode pair, Facts/Path pair, Settings).
  This reverses part of D-016's "the header is a mode switch and Settings, and nothing else" — the
  founder asked for it explicitly, so it is a decision, not a regression.
- `PanelLayoutTests` follows the rename; the stored-preference round-trip test still passes on the
  old raw values, which is what pins the migration.
- `Stack`/`Chain` survive only as raw values and as internal widget names (`ChainCard`, `ChainLink`),
  which were left alone — they are components, not readings.

### Revisit when

The Path reading gets too tall in the narrow list column, or the Facts column stops carrying
something Path cannot.

---

## D-020 — "Up but not attached" is its own visual state; a running IDE is not a dead install

### The problem

The founder's key moment: with two IDEs open at once — OpenCode and DeepSeek Harness — *neither
appeared* on the text panel or the graph. Investigation showed this was **not** a detection failure.
`doctor` reported both correctly as `Running`, and the bridge carried them in `latent_harnesses[]`
with `rung: "running"` (OpenCode under `cli:opencode`, D-015's CLI identity).

The gap was one layer up, in the drawing. The 2D pool gave every node `glow = 0` unless it was
`isLive`, and a running-but-unattached harness is correctly *not* `isLive` — nothing answered on a
port and it is not driving the engine. So a running IDE rendered **pixel-identical** to an app that
was installed and never launched. The engine had told the two rungs apart; the drawing threw the
distinction away. In the dial, the same harness was listed with `isEnabled: false`, which reads as
broken rather than as *up*.

### The decision

- **`HarnessRung.isUp`** (`self != .present`) is the honest "a process owns it, or something answered
  in its name" test, distinct from `isAttached`.
- A node that is `isUp` but **not** `isLive` gets a **steady glow** (`0.34`, radius 5, presence
  `0.72`) and its glyph's `isActive` set, so it reads as lit. Steady and **never pulsing**: the
  breath stays reserved for `isLive`, because being up is not the same as carrying work, and
  foundation §2 forbids claiming a rung that was not reached.
- A `.present` (installed, never run) harness is unchanged: no glow, presence `0.5`. The two
  dormant-looking rungs are now genuinely distinguishable.

### The consequences

- `isLive` semantics are untouched — no test changed meaning, and the "exactly four live nodes" pin
  still holds. This is purely a drawing change on top of the rung the engine already reported.
- The 3D room reads `isLive` directly (`GraphScene.isLive`), so the deep still treats a running
  harness as not-live. Making the deep match the flat pool's rung-aware treatment is **not** done —
  it follows whenever the deep is next looked at.

### Revisit when

The graph grows a third "up but idle" rung, or the founder wants a running harness to breathe as
well as glow.

---

## D-021 — A configured provider is a rung-0 declaration; an MCP URL is never a model route

### The problem

The founder's ask: *"the IDEs need to be shown to be hooked up to whatever they may
be hooked up to. They might be getting inference from somewhere else."* This was the
**harness-config reader**, recommended in D-015, D-017 and D-018 and flagged as the
single blocker across four handoffs. It is built as `src/sea_star/providers.py`.

The premise the handoffs recorded turned out to be stale: they cite
`~/.config/opencode/opencode.json` naming `"model": "atomic/Dirk-…"`. That entry no
longer exists. The live file declares **two MCP servers and no model at all**. So
the reader had to find the fact from wherever it actually lives — and, more
importantly, had to not mistake what is there.

### The decision

- **A configured provider is a declaration, never a connection.** Foundation §2 rung 0.
  A configured provider holds no socket, so no probe could ever have shown this
  edge — it is the one link of the cascade only a config read can supply. It is
  drawn as a stated binding, never as liveness, and the graph gains no node kind.
- **Only an inference surface may produce a claim.** `_is_model_route` admits a
  URL ending in `/v1`, `/v2`, `/models`, `/completions`, `/embeddings`, or a bare
  loopback port with no path; it rejects anything whose path names `/mcp`. This
  exists because the first implementation did exactly what the project already
  logged once as D-010 ("a port is not a server"): it accepted any URL and
  reported **`https://mcp.exa.ai/mcp` as OpenCode's model provider**. The presence
  of a URL is not the shape of a model claim.
- **Derived fields only.** The claim carries `(provider, base_url, model)` and
  nothing else. API keys, tokens and the raw document never enter the result, and
  the dataclass is frozen. A test asserts a config full of secrets yields a claim
  containing none of them.
- **Resolution is by identity, both ways**, so the engine's short key (`opencode`)
  finds the app the graph calls `OpenCode` — and a harness nobody declared for
  gets `nil`, never a neighbour's claim.
- **A claim resolves to an endpoint only when Sea-Star can already see that
  endpoint answering.** A declaration for an unseen port, or a cloud route, stays a
  label on the node's subtitle. Inventing a node for it would be a new claim.
- **Focus views read the same `isLive` facts as the whole-pool view.** The focus
  edge layer previously drew *every* wire blue-white, so a live connection and a
  dormant one became indistinguishable the moment you clicked a star — the exact
  confusion the founder spotted, and a regression of the whole-pool rule.

### The consequences

- Bridge key `providers[]` is additive; `schema_version` stays `1`; an older engine
  yields `[]` and the app says nothing rather than inventing a picture.
- On this machine the honest reading is **empty**: OpenCode declares no model, so
  Sea-Star reports no declaration. That is the correct answer, not a failure — and
  it is why the reader had to be built on evidence rather than on the handoff's
  remembered example.
- 15 new Python tests (179 total), 7 new Swift tests (102 total, 18 suites).

### Revisit when

A harness is found whose settings name its inference somewhere this reader cannot
reach, or when the founder wants a declaration to create its own endpoint node
rather than only annotate an existing harness.

---

## D-022 — A workspace is where a harness is pointed, not a row of marker files

**Date:** 2026-10-08 · **Founder:** in session · **Tier:** 2 (architecture bet)

### The decision

**The Workspace panel row is removed.** A workspace becomes a property of a harness:
the directory that harness is pointed at. Every marker-file scan that fed the row is
gone with it.

### Context

The row appeared in a session with no decision behind it, and the founder reopened it
with: *"it's a meaningless sort of word… what comes up as displayed is like a string to
a markdown file for agents. Let's redefine that as being more connected to CLI."*

Three defects, all verified rather than argued:

1. **It was a mirror.** It detected agent artefacts in
   `FileManager.default.currentDirectoryPath` — the directory the *app* booted from.
   For a menu-bar app that is arbitrary, so the row described Sea-Star rather than the
   person's machine.
2. **It was another hardcoded name list.** `.claude`, `.cursor`, `.opencode`, `.codex`,
   `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` — the same defect as `KNOWN_HARNESS_COMMANDS`,
   and the trap the foundation exists to escape.
3. **It sat at the wrong level.** Vault/Harness/Agent/Inference are things you *use*; a
   workspace is a *property* of one of them.

### Consequences

- The row disappears; **nothing replaces it in the panel**, so the panel loses a row.
- Where a harness is pointed is read from the process (`lsof -a -p <pid> -d cwd`),
  which is also what makes a CLI agent distinguishable from a desktop app: a CLI has a
  working directory, an app usually has none and then says nothing.
- The engine-side workspace plumbing is **kept** and reused: `agents/` directories
  beneath the pointed-at directory are the agents that harness can reach (D-023).
- `docs/WORKSPACE-IMPLEMENTATION.md` now records the failure rather than describing
  the row as shipped.

### Revisit when

A person has harnesses pointed at many directories at once and wants the graph to draw
those locations as places in their own right.

---

## D-023 — Agents are read by shape, not from one harness's private store

**Date:** 2026-10-08 · **Founder:** in session · **Tier:** 2 (architecture bet)

### The decision

The agent roster reads **two families of source and unions them**: a harness's own
store, and **agent files as a shape** — a Markdown file with a delimited header
(`name`, `description`, `model`) inside a directory named `agents/`.

### Context

The cockpit showed **"no roster found"**, which the founder read correctly as
meaningless. It was not measuring anything: it looked in exactly one place, one
harness's private JSON store, and presented the result as *"you have no agents"*.
The person may have had a dozen agents written as files.

Research into how agent tooling actually works showed the definition format is a
convention, not a product: agent files are Markdown with a small header, living in an
`agents/` directory — **the same directory name the JSON store already uses**. So the
*layout* is the discriminator and no product name appears in the code.

- **The directory name is the convention; the file shape tells you which tool.**
- A harness invented tonight is read because its files have the shape.
- Sources are **unioned, not first-match-wins**: returning the first non-empty source
  reported a roster that existed and silently omitted the rest — the same lie as
  reporting none, and harder to spot because the row looked populated.
- The header reader recognises plain `key: value` scalars and deliberately stops
  there. `tools`, `effort` and `mcpServers` are not read because nothing acts on
  them, and reading less keeps this from becoming a second implementation of somebody
  else's configuration format. No YAML dependency was added.
- An unterminated header, a README, or a file with no name yields **no agent** rather
  than a phantom one.

### Consequences

- On this machine the honest reading is **empty**: `~/.claude` exists but holds no
  `agents/` directory. That is now a true reading of both families rather than one.
- 8 new Python tests, including one proving a dot-directory nobody in this codebase
  has heard of (`.vibeweaver/agents/`) is read purely by its layout.

### Revisit when

An agent definition needs a field Sea-Star must act on — a declared model it cannot
currently honour, or a tools list it should be filtering by.

---

## D-024 — One agent is one root process, and an unnamed one still counts

**Date:** 2026-10-08 · **Founder:** in session · **Tier:** 2 (architecture bet)

### The decision

An agent **instance** is a root process that behaves like an agent. Helpers collapse
into their parent. **An instance with no name is still reported.**

### Context

The founder's framing, which set the design: *"I've got OpenCode in two instances
running right now, and essentially even if they don't have names, they are still
agents. Because that's what I'm talking to."*

A desktop agent is a dozen processes — app, CLI, helpers, renderers. On this machine
OpenCode is **8 processes right now**. Counting them would call one conversation
eight agents. But a naive collapse that folded the CLI into the app would hide the
second conversation entirely.

So: a candidate whose ancestor **of the same product** is also a candidate is a
helper, and is dropped. Product matching reads the `.app` bundle in the path, falling
back to the executable stem — no product name is hardcoded. Two OpenCode instances
therefore stay two agents.

**Running this live caught a category error before it shipped.** The first candidate
set included `oMLX`, which is an inference *server*, not an agent. Filing it as an
agent is precisely the error that made the cockpit unreadable once already — and
Atomic Chat genuinely does **both**: drives Sea-Star *and* serves the model it drives
it through. Forcing either single label loses half the truth, so **two roles are
recorded separately** (`is_attached`, `serves_models`) and the caller decides the
wording.

### Consequences

- Live on this machine: 5 candidate processes → 5 instances, with oMLX marked *serves
  models* and Atomic Chat marked *drives Sea-Star* — each fact attached to the thing
  it is true of.
- Declining to show work in progress because no persona file exists is the same
  blindness the name-less CLI had (D-025), and is refused.
- A pid whose working directory cannot be read is **absent**, never guessed.
- 5 new Python tests.

### Revisit when

Sub-agent work needs to be attributed to a named parent, which requires modelling the
hierarchy rather than flattening each process into one root.

---

## D-025 — A CLI is recognised by what it serves, not by what it is called

**Date:** 2026-10-08 · **Founder:** in session · **Tier:** 2 (architecture bet)

### The decision

A CLI agent is recognised as **the process holding a loopback port that answers as a
model server**, whatever its executable is called. The six known command names remain
as an additive hint and are **never a gate**.

### Context

`running_command_harnesses()` matched on process name against `KNOWN_HARNESS_COMMANDS`
— six names. The comment claimed a missing name was harmless because other families
would still find the harness. **For a headless CLI that is false:** a bare CLI has no
bundle, no `Info.plist`, no port and no client connection, so the name list is the
*only* mechanism that can see it. Any agent invented after that dict was written was
invisible, permanently.

Worse, the claim was **an agent's rationalisation, not a founder decision** — nobody
asked and it was never approved. The founder's requirement had been stated plainly:
*"if a CLI is invented overnight from some vibe coder and someone downloads it, then
it's gotta hop in there."*

The codebase already held the right pattern in `recon.MODEL_VOCABULARY`, whose own
source says a vocabulary *"generalises to software nobody has written yet; a list of
app names cannot, and this module deliberately has none."* The CLI family was the
outlier against a rule the project had already written down.

### Consequences

- Only ports **proven** to answer with a model list count (only `config` speaks HTTP,
  and is the sole source of that proof). A port with no known owner is skipped rather
  than guessed at.
- Verified with controls rather than assertion: on this machine 9 things listen on
  loopback and only the model-serving ones qualify — `ControlCenter` (5000, 7000),
  `rapportd` and `python3.11` all stay out, and `TextEdit` launched as a live control
  does not appear.
- The port **sweep list is not a gate either**: reconnaissance observes every listening
  port and threads them in, so an unknown port is probed regardless.
- 5 new Python tests, including one asserting a CLI named `nightfall-agent` is found
  *while a test asserts that name is absent* from `KNOWN_HARNESS_COMMANDS`.

### Revisit when

A process behaves like an agent but serves no model — a headless agent with a remote
endpoint only. That case is invisible today and the honest answer is that it is not
yet solved.

---

## D-026 — The cockpit watches continuously, and only redraws on real change

**Date:** 2026-10-08 · **Founder:** in session · **Tier:** 3 (runtime behaviour)

### The decision

The cockpit re-reads the machine **every 2 seconds while open**, and **a reading is
adopted only when it differs** from the last one.

### Context

Two separate failures, both reported by the founder:

**It did not listen.** It read the machine three times — on open, on Refresh, and after
a setting changed — and **never in the background**. So working in DeepSeek Harness for
an extended period left the panel describing a machine that had stopped existing. The
founder's report: *"as soon as any harness fires up, it's gotta be able to hear it
update… I was building it in DeepSeek Harness for a while and it never actually saw
that as live."* Cancellation is the off-switch, so a closed cockpit costs nothing.

**Then it flickered.** Watching made every node blink every two seconds: `adopt`
assigned the report unconditionally and the graph model is a computed property rebuilt
on every render pass, so each poll restarted the pulse animation from zero. The Logs
panel also gained an identical line every two seconds, and the status dot flipped
colour on each poll.

The founder's assessment: *"it really shouldn't be happening and possibly could give
somebody an epileptic fit."* **A rapid full-brightness flicker is a genuine hazard for
photosensitive users, not an irritation** — and it would have shipped unflagged.

### Consequences

- `adopt` returns `Bool` and assigns only on a real difference (`DoctorReport` is
  already `Equatable`). Everything downstream is a function of change, not of the clock.
- `logs.append` is gated on the same change, so the Logs panel no longer scrolls for
  ever.
- The status dot no longer reads `isRefreshing`: a background poll is not a "checking"
  state and must not be drawn as one. `isRefreshing` still governs the Refresh button.
- 102 Swift tests in 18 suites pass.

### Revisit when

The 2-second interval proves too eager on battery, or too slow to feel live.
