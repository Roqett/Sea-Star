# Changelog

All notable changes to Sea-Star are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Harness: DeepSeek Harness

Date: 2026-10-02 17:30 ACST

Summary of Changes:
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — retired the graph "Both" comparison: the depth switch offers Pool and Deep only, and the side-by-side branch is gone (D-003).
- `macapp/SeaStar/Views/CockpitPanel.swift` — retired the text "Both" comparison: `PanelLayout` is now Stack and Chain only, and the compare layout is gone (D-003).
- `macapp/SeaStar/Support/Strings.swift` — dropped the "Both" labels, help lines and icons from both switches.
- `macapp/SeaStarTests/DoctorReportTests.swift` — panel-layout tests now expect two layouts, not three.
- `docs/cockpit-look.md`, `assets/cockpit-proposal.png` — the cockpit reconception proposal: one interactive graph, one text panel, inference as its own kind.

Harness: DeepSeek Harness

Date: 2026-10-02 18:50 ACST

Summary of Changes:
- `src/sea_star/harnesses.py` — a known harness app now reports the rung it reached. `running_app_paths()` reads the process table once so an app that is up but not answering is `running`, not the same grey as a dormant install; `app_bundle_in()` is shared with `connections.py` so both readers agree what an app is. DeepSeek Harness (`com.deepseek.dsh`) added to `KNOWN_HARNESS_APPS` — the harness the founder is talking to is now on its own graph (D-004).
- `src/sea_star/connections.py` — the duplicate `.app` path regex is deleted; `_app_in` delegates to `harnesses.app_bundle_in`.
- `src/sea_star/cli.py` — `latent_harnesses` entries carry `rung`; `doctor` prints `Running:` separately from `Latent:`; the multi-endpoint line is relabelled `Inference:` (it was printing endpoints as "Harnesses").
- `macapp/SeaStar/Services/ServerController.swift` — `HarnessOption` → `InferenceOption` and `harnessOptions` → `inferenceOptions`: an endpoint is inference, a harness is the app driving Sea-Star. Adds `HarnessRung`, `attachedHarnesses` (the engine's connection record) and `InferenceOption.isRemote`.
- `macapp/SeaStar/Views/EntityGraphModel.swift` — `Kind.latent` is deleted and `Kind.inference` added: five kinds matching the ontology. Harness nodes come from attached hosts and from known apps carrying their rung; inference nodes are teal locally and plum for a remote API; `activeHarnessID` → `activeInferenceID`. Readouts now name things — the models an endpoint serves, the personas riding them, an attached host's pid, start time and the `ask_seastar` tool it calls — instead of "5 models".
- `macapp/SeaStar/Views/EntityGraphView.swift` — node sizes and the dim-for-unattached rule follow the new kinds; the per-node hue smear narrows from ±25% to ±6% so a plum API cannot drift red and a teal local runtime cannot drift blue.
- `macapp/SeaStar/Views/CockpitPanel.swift` — the `Harness` row is a reading of the app driving Sea-Star; the endpoint picker moves to `Inference`, where the ontology puts it.
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — a harness app that is up but not attached says so in the list.
- `macapp/SeaStar/Models/HarnessTips.swift`, `Support/Strings.swift` — the note beside the active star names the model it is answering as instead of counting models on offer; the now-unused `modelCount` helper is deleted so the count copy cannot come back.
- `macapp/SeaStar/Support/Palette.swift`, `Support/Strings.swift` — vault bone, inference teal, API-plum tokens; rung words ("Driving Sea-Star now" / "Up, not answering yet" / …) and the string set the readouts need.
- `macapp/SeaStar/Models/DoctorReport.swift` — `LatentHarnessInfo` decodes the optional `rung`, absent from an older engine.
- `macapp/SeaStarTests/EntityGraphTests.swift` — fixture gains an attached host and rungs; tests pin four live nodes, an unattached harness having no edges while an attached one is wired to its vault, and an endpoint readout naming models rather than counting them.
- `src/sea_star/harnesses.py` — **the `/Volumes` sweep is gone by default.** A mounted volume is read only when a caller names it, because the founder's no-go rule puts his external drive off-limits and an unconditional sweep is precisely the quiet visit that rule prevents. `tests/test_harnesses.py` now asserts the default read does not go near a volume.
- `tests/test_harnesses.py`, `tests/test_cli.py` — rung detection, the shared `.app` reader and the bridge's `rung` field.
- `DECISIONS.md` — D-004.
- `src/sea_star/recon.py` — **new.** Triggered reconnaissance of this machine's own process and socket tables: every listening port and live outbound connection, each attributed to the `.app` owning the process tree, so a model server held by a bare helper is still credited to its app. Recognition is runtime vocabulary plus the machine's own register — no list of app names takes part (D-005). Reading *who is connected to whom*, never the contents.
- `src/sea_star/cli.py` — the report gains `listening`, `model_like` and `outbound`; `doctor` prints `Serving:` and `Leaving:`. The register is matched by identity — display name, bundle path or folder name — after a live endpoint was lost to "Unsloth Studio" vs "Unsloth".
- `tests/test_recon.py` — **new.** 14 hermetic tests over canned `ps`/`lsof` output: attribution up the process tree, honest absence when no app owns a process, deduplication, loopback vs network, vocabulary vs register, and the identity-matching bug above.
- `DECISIONS.md` — D-005.
- `src/sea_star/register.py` — **new.** The register: one verdict per thing, keyed by bundle id or path and never by display name, stored in `~/.seastar/register.json` and written only by the engine. Discovery gathers six evidence families (listening services, outbound connections, MCP tool lists on disk, agent state directories, workspace artefacts, and the seed table) into candidates that each carry the observed facts behind them. Vocabulary candidates qualify only on a protocol word, because browsers ship AI brand names as blocklists (D-006).
- `src/sea_star/cli.py` — `harnesses [--scan] [--workspace]`, `adopt`, `dismiss` and `forget`; the bridge carries `candidates`, which is what lets the cockpit ask without keeping its own copy of the decision.
- `tests/test_register.py` — **new.** 18 hermetic tests: round trips, a dismissal remembered as a decision, a malformed register left intact, atomic writes, evidence merged from two families into one question, plain installed apps not accused, and the browser false positive pinned so it cannot return.
- `macapp/SeaStar/Models/DoctorReport.swift` — decodes `candidates` and their evidence; `undecided` is empty for an engine that predates the register.
- `macapp/SeaStar/Models/EngineCommand.swift`, `Services/EngineClient.swift` — `adopt` / `dismiss` invocations and a `record` that fails loud when a verdict does not save.
- `macapp/SeaStar/Services/ServerController.swift` — `candidates`, and the two answer actions; the app asks and the engine remembers.
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — the `New on this machine` section: each candidate's evidence above an editable pre-filled name and the two answers. Asked once, ever.
- `macapp/SeaStar/Support/Strings.swift` — the register's labels and the plain words for a verdict that did not save.
- `macapp/SeaStarTests/DoctorReportTests.swift` — candidate decoding pinned, including that evidence survives and an older engine asks nothing.
- `DECISIONS.md` — D-006.
- `src/sea_star/recon.py` — `machine_summary()`: the machine in plain lines for a caller that cannot draw it, naming the app every inbuilt model server belongs to and saying that it stops with that app. One rendering, shared.
- `src/sea_star/register.py` — `recognised_names()`: one definition of what this machine recognises (register verdicts, attached hosts, the seed table, names *and* paths). It was being assembled inline in the bridge and would have needed a second copy for MCP (D-007).
- `src/sea_star/mcp_server.py` — **new tool `machine_report`**: an attached harness can ask where models are coming from, which servers are inbuilt, and what is leaving the machine. The symmetry clause, and read-only.
- `src/sea_star/cli.py` — the report's recognition set now comes from `recognised_names()`, so the cockpit and the MCP answer cannot disagree. `model_like` entries carry `app_name`/`app_path`.
- `tests/test_mcp_server.py` — the tool surface includes `machine_report`, and a host is shown to get an answer from it.
- `macapp/SeaStar/Models/DoctorReport.swift` — decodes `model_like` and its owner; `isBundled` names the case that matters.
- `macapp/SeaStar/Services/ServerController.swift` — `bundledOwner(of:)` and `currentEndpointIsBundled`, read from the port rather than assumed from a name.
- `macapp/SeaStar/Views/EntityGraphModel.swift` — an endpoint readout names the app it runs inside, and warns in plain words when that endpoint is the one Sea-Star is thinking with.
- `DECISIONS.md` — D-007.
- `src/sea_star/recon.py` — `harness_ledger()`, `harness_behaviour()` and `ledger_lines()`: one row per app saying what it serves, whether it is using its own server, and what it reaches for outside. Observations only — there is no field for motive, and "not using them" is deliberately never said, because the server may be in use by Sea-Star itself (D-008).
- `src/sea_star/cli.py` — the bridge carries `behaviour` at the top level, beside the other machine reads.
- `src/sea_star/mcp_server.py` — `machine_report` answers with the ledger too, so a host learns who is doing what and not merely where models are.
- `tests/test_recon.py` — the ledger pinned: serving vs using vs reaching, the flagged case firing only on all three, a browser kept out of the sentences, and the "not using them" wording banned.
- `tests/test_cli.py` — a test for the exact bug that shipped: `behaviour` must be top-level and not nested inside `vault` (the insertion anchor matched the vault's own `candidates` key). An autouse fixture now keeps every doctor test off the real machine — they had begun reading the live socket table and took seven seconds.
- `macapp/SeaStar/Models/DoctorReport.swift` — decodes the ledger; the type has no field for intent.
- `macapp/SeaStar/Services/ServerController.swift` — `appBehaviour`, the ledger as the engine observed it.
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — the `What each app is doing` band, with the flagged row in the warning colour.
- `macapp/SeaStarTests/DoctorReportTests.swift` — the ledger's decoding pinned, including that the flagged case arrives as two facts.
- `DECISIONS.md` — D-008.
- `src/sea_star/harnesses.py` — `declared_url_schemes()`, `is_web_client()` and `is_system_component()`: two barred roles, both *declared by the app or by its location* rather than named. Every browser must claim `http`/`https` in its own Info.plist, so the OS already keeps the browser list and Sea-Star reads it (D-009).
- `src/sea_star/register.py` — **traffic no longer raises a candidate.** Outbound connections are applied after the other families as enrichment, which is what removes browsers, messengers, updaters and VPNs from the question list. Also: an app's own tool list merges into that app, so Atomic Chat and TRAE SOLO are asked about once each rather than twice.
- `src/sea_star/recon.py` — the barred roles are applied in the ledger *and* inside the unfiltered `harness_ledger`, so no route exists by which a browser becomes a harness; a web client's loopback port is never inference.
- `tests/test_register.py`, `tests/test_recon.py` — the strategy pinned: a declared web client is never proposed even while reaching outside, a system component is never proposed, traffic alone raises nothing, traffic enriches a question already raised, and an app keeping a tool list is asked about once.
- `DECISIONS.md` — D-009.
- `src/sea_star/recon.py` — **a port is not a server.** `HarnessBehaviour` carries `serves` (ports an OpenAI probe answered on) and `listening` (ports that merely look like servers), with `unconfirmed` as the difference. The flagged case now requires a *proved* server, which removes a live false accusation: DeepSeek Harness's 19387 serves its own interface and no models (D-010).
- `src/sea_star/cli.py` — the report threads the answered ports through by hand, because probing is HTTP and `recon` deliberately does not speak HTTP; `model_like` entries carry `answering`.
- `src/sea_star/mcp_server.py` — `machine_report` awaits the probe instead of calling a sync wrapper. The wrapper used `asyncio.run` inside the server's own event loop and failed at the first call.
- `tests/test_recon.py` — a port that never answered is never called a server, and the flagged case cannot fire on a guess.
- `macapp/SeaStar/Models/DoctorReport.swift` — decodes `answering` and `listening`; an older engine reads as *unproved* rather than being credited with an answer it never gave.
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — the row says "listening 8888, not answering" where it used to claim serving.
- `DECISIONS.md` — D-010.
- `macapp/project.yml` — **two build configurations.** Debug stays ad-hoc and unsigned so anyone can build without an Apple account; Release requires the hardened runtime and a Developer ID, and *fails to build* without one rather than silently producing a DMG Gatekeeper would refuse. The Team ID is supplied by the release script, so no account identifier is committed (D-011).
- `script/release.sh` — **new.** Build, sign, package, notarise, staple and verify, checking the certificate, Team ID and notary credential before the build rather than after it, and ending on Gatekeeper's own verdict via `spctl`. `--dry-run` proves the pipeline without an Apple account and labels its output as unsigned.
- `docs/ship.md` — **new.** The one-time Apple setup in plain language, why the script does each step in that order, the two distribution routes and why the App Store is closed to this design, and the remaining packaging gap stated as the headline rather than a footnote.
- `DECISIONS.md` — D-011.
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — the cockpit is a reading again: list mode is the four rows, graph mode is the starfield with the float/take-off list beneath it, and the whole panel has a hard height ceiling with one scroll region so the header can never be pushed off-screen (D-012). The ledger, register and idle sections leave the popover.
- `macapp/SeaStar/Views/OnboardingView.swift` — **new.** The onboarding window: the behaviour ledger, the full register with evidence, and the graph's cast list, in the house style. `HarnessVisibilityList`, `LatentRow`, `BehaviourRow` and `NewCandidateRow` move here from the cockpit.
- `macapp/SeaStar/App/AppDelegate.swift` — an onboarding window with a menu item ("Set up Sea-Star…") and one-shot first-run logic; the window is marked seen only after it is actually up. **Also fixes a dormant bug:** the popover open/close flag was never set because the delegate used the pre-macOS-14 `popoverDidShow(_ popover: NSPopover)` signature, which compiles silently and never fires; it now takes the SDK's `Notification` and is verified to round-trip.
- `macapp/SeaStar/Views/CockpitPanel.swift` — the Vault card's second line is the note count rather than the word "Notes", and the Harness card says plainly that no app is driving Sea-Star instead of borrowing another app's rung.
- `macapp/SeaStar/Views/SettingsView.swift` — the generic grouped form is replaced with the house style: canvas, ink, accent bars, mono headings and plain word buttons, plus a door to onboarding.
- `macapp/SeaStar/Support/Strings.swift` — onboarding copy, the honest "On your graph" heading, empty states, and the note-count line.
- `DECISIONS.md` — D-012.
- `src/sea_star/agents.py` — `placement()`: the cascade's last hop as one rule with three honest cases — served by a running endpoint, built for a provider that is up but not serving it, or nowhere at all (D-013).
- `src/sea_star/mcp_server.py` — `machine_report` answers "Agents and where they run": every agent, its model, and its placement, so a host hears the same cascade a person sees.
- `macapp/SeaStar/Services/ServerController.swift` — `selectedAgent` and `placement(of:)`, the same rule in Swift.
- `macapp/SeaStar/Views/CockpitPanel.swift` — the Inference row speaks the selected agent's placement beneath the pickers.
- `tests/test_agents.py` — the three placement cases pinned, including the live trap where the provider is up and the model is not on offer.
- `macapp/SeaStarTests/EntityGraphTests.swift` — the panel's placement for the fixture cast: served, served-elsewhere, and unbound.
- `DECISIONS.md` — D-013.
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — the two nudibranch strips framing the Start/Refresh controls are removed. They were pure decoration from the early visual spec, and the founder asked for them off more than once; they survive only where the strip *says* something (the live-connection ribbon in the starfield, the liveness bar, the expanded log frame).
- `macapp/SeaStar/Views/EntityGraphView.swift` — the two green-orange liveness bars floating above live nodes in the starfield are removed. The founder asked for them off across multiple sessions; every session defended them as information. They were redundant — the node's glow already says the same thing.

Harness: TRAE

Model: unknown (the active harness does not report its own model id to this session)

Routing: omlx → Dirk-Qwen3.8-27B-MLX-oQ6e (per `sea-star doctor` on this machine)

Date: 2026-09-30

Summary of Changes:
- **The two-window game plan, executed (D-002).** The cockpit now has two windows with one
  independent axis each: the text window arranges the four rows behind
  `SeaStar.panelLayout` — **Stack** (default), **Chain** (connected request-path cards),
  **Both** (side by side; 360pt column, 660pt for the comparison) — and the graph window
  picks its renderer behind `SeaStar.graphDepth` — **Flat** (default 2D starfield),
  **Deep** (3D), **Both** — at 600pt wide (960pt for the comparison), 560pt tall (600pt
  Deep). Comparison is opt-in per window and the defaults show one design each, so nobody
  lands on both-of-each at once.
- **The four-row panel's observation made honest.** The endpoint no longer prints twice —
  it lives under *Inference*, and the Working-now band keeps it as a hover help string
  only; the redundant liveness word is off the row; the header bar tightened 555→54pt.
  `Working now` stays probe-evidence only (D-001): never a prompt, an output, or a persona
  acting.
- **One shared graph model for both renderings.** A new renderer-independent
  `EntityGraphModel` feeds the 2D starfield and the 3D room, so the readings can never
  disagree with each other or with the rows.
- **2D nodes are colour-coded by kind, glow only when active, and identify themselves on
  hover.** Vault teal / harness+latent electric blue / model neon green / agent orange,
  each hue-shifted deterministically from its own id so a kind reads as a genre with
  variation (the C-star treatment) instead of clones; full glow only when active or
  selected, a dim breath when live, plain definition when idle; the hover readout card
  names every node — discovery without clicking ("people don't like clicking").
- **The 3D room got a legibility pass.** Bloom, body emission, additive glyphs and label
  weight pulled back, motes thinned 0.30→0.20, camera brought closer — its star shells
  keep their definition beside the flat drawing instead of blowing out.
- **Animation now runs only while the panel is open.** The popover delegate writes
  `SeaStar.cockpitOpen` (default false) into the environment; caustics, grain, the 2D
  timeline, the SceneKit render loop and the liveness drift all gate on it — closing the
  panel stops exactly the repaint-and-drift surfaces the ~23% CPU diagnosis identified.
  No delegate signal means *still* (the safe failure), and the server/MCP connections are
  untouched: close it, the motion shuts, the connections hold.
- **The orange/green liveness bars are visibly alive now.** Sweep doubled (2× scale, 8pt
  travel) with no new timers or repaints — amplitude, not frequency. Blue-white strips
  remain the resting treatment everywhere else.
- **Connectors now actually connect.** The 2D starfield's strips overshot both endpoints:
  `NudiStrip(expands: false)` swallowed the caller's fixed width and sized itself from the
  743×3px art (~495pt wide at 2pt tall), so focus-mode edges shot past their nodes "to
  oblivion". It now honours the caller's width exactly — the fixed length spec §8 always
  promised — and the decorative star backdrop dissolves in focus mode, so every line on
  screen in focus is a real node→node edge and no ray points at empty space.
- **Agent roster reporting (Python engine).** `displayName` fallback so Osaurus agents
  keep their friendly names, the harness's default agent (the orchestrator) ordered first,
  and new `detect_agent_roster` / `AgentRoster.source` reporting *which harness* a roster
  belongs to.
- **Connected hosts are no longer reported as latent (the structural fix).** The doctor
  called a harness latent when no port answered it — but a harness like TraeWork attaches
  over **stdio** and never answers a port, so it looked idle while actually connected.
  `serve` now records who spawned it (`~/.seastar/clients/{pid}.json`; identity found by
  walking up to 8 parent processes to the `.app`, stored as derived name/bundle-id/path
  only — never raw command lines; record pruned automatically when the process dies, so a
  crash can't leave a ghost). The doctor counts recorded hosts as **active**, drops them
  from `latent_harnesses[]`, and reports them under a new additive `mcp_clients[]` key
  (`name`, `bundle_id`, `pid`, `started_at`; `schema_version` unchanged, older apps still
  decode). The cockpit decodes the key and the Working-now band shows a live **Host** row
  whose evidence line names the proof — a connection record is not a port probe, so the
  line says which one it is standing on. All three layers now agree: engine records →
  doctor reports active → panel shows attached.
- **Verified:** 70 Swift tests in 13 suites; 97 pytest in 0.38s; ruff clean; live
  `doctor --json` showed both the cockpit's serve (`Sea-Star`, pid 30999) and TraeWork
  (`com.trae.solo.app`, pid 31147) under `mcp_clients`, with TraeWork gone from the latent
  list; earlier entry's numbers (68 Swift / 84 pytest) superseded by this run; Release
  bundle 4.4MB vs the 3.6MB baseline stands — Resources unchanged at 136KB, growth is
  compiled 3D code only.

Harness: TRAE

Model: unknown (the active harness does not report its own model id to this session)

Routing: omlx → Dirk-Qwen3.8-27B-MLX-oQ6e (per `sea-star doctor` on this machine)

Date: 2026-09-26 (late — a **backfill**, see note)

Summary of Changes:
- **Backfill for two commits that shipped without an entry.** The graph work below was
  committed and pushed on 2026-09-26 (`f427d37`, `74f63b9`) but never written up here, so
  the changelog described a *smaller* product than the one that had actually shipped. This
  entry records **only what those two commits contain**; later uncommitted work on the same
  view is written up in the 2026-09-28 entry below and is deliberately not claimed here. The
  original commits are untouched, per the append-only rule.
- **The cockpit graph became a tactile, star-shaped, multicoloured canvas** (`f427d37`). The
  starfield is no longer a scatter of dots: the majors — the **vault** and its **harnesses**
  — now sit on the **tips of an N-pointed star**, drawn out to the panel edge, with a faint
  star outline and rays behind them. So four majors read as a four-pointed star and seven as
  seven, and the *shape itself* is a count of what is connected. Each node wears a
  five-armed sea-star glyph whose hues are **seeded from its entity id** — never random, so a
  given vault/harness/model always spins the same blend around its own colour. The pool
  became an object you handle: **drag to pan, pinch to zoom, twist to turn**, with a recentre
  control to tide it back. Panel widths followed: **graph 600pt, list 360pt**, so the tip
  note never truncates, and Start/Refresh gained a tactile hover ground.
- **Clicking a node blooms a detail card** (`74f63b9`). A sea-star was already hoverable and
  clickable but said nothing back, which made the graph look alive and feel dead. A click now
  opens a small card carrying only facts the engine had **already** handed over in the report
  — no second call: for a **vault**, the note count, how it was found, the other vaults
  nearby and the full path; for a **harness**, its endpoint, how many models it serves, and
  whether it is current or merely available; for a **model**, which harness serves it and
  whether it is current or available. All copy lives in `Strings.Detail`.
- **A mouse can drive the pool** (`74f63b9`). Only a trackpad can pinch and twist, so without
  help a mouse user could not zoom or turn the graph at all. An **app-local event monitor**
  now reads the wheel and a right/middle-drag while the popover is open, zooming **toward the
  cursor** (the point under the pointer stays put) and spinning the pool like an object in
  the hand. The monitor swallows the event so nothing behind the graph reacts, and its
  `hitTest` returns `nil` so ordinary clicks and hovers still fall through to the sea-stars
  beneath it — the catch never blocks the thing it is catching. The pan hint now names both
  devices.
- Verified at the time of the backfill: `xcodebuild … build` → **BUILD SUCCEEDED**;
  `xcodebuild … test` → **29 Swift Testing cases in 8 suites passing**; `uv run pytest` →
  **76 passed**; `uv run ruff check .` → clean. All four re-run during this backfill, not
  quoted from an earlier note.

Harness: TRAE

Model: unknown (the active harness does not report its own model id to this session)

Routing: omlx → Dirk-Qwen3.8-27B-MLX-oQ6e (per `sea-star doctor` on this machine)

Date: 2026-09-28

Summary of Changes:
- **New binding foundation document (`docs/foundation.md`).** The founder identified that
  Sea-Star had been built around the specific harnesses installed on his machine rather
  than around capabilities, and asked for that to be written down as a foundation rule. The
  lead clause is **"no name is ever a precondition"** — every known name is a hint that
  improves a label, and its absence may never reduce what is displayed. Records the
  eight-rung **capability ladder** (declared → present → running → listening →
  self-describing → agent-aware → activity-aware → caller-attributed), the **degradation
  contract** (show the highest rung reached, and show the rung; never claim above what was
  established), **MCP as the generic adapter** (ask an unknown harness rather than know it),
  and a symmetry clause — anything Sea-Star can prove must be callable over MCP, not only
  drawable in the app. Four items of **known debt** are logged against the document so the
  gap is visible rather than rediscovered.
- **`AGENTS.md` now points at `docs/foundation.md`** as the foundation document (previously
  `README.md` "until `docs/` exists"), and `docs/README.md` indexes it. The repository front
  page is explicitly the shopfront, not the foundation.
- **New `DECISIONS.md` (D-001), and the panel ontology is now decided rather than open.**
  `AGENTS.md`'s definition of done requires a decision to be recorded here whenever it affects
  architecture, UX flow, or product values, and the `Harness`/`Agent`/`Inference` split is
  exactly that. The founder raised the split and then explicitly declined to resolve it, so the
  call was made under the one-recommendation rule and the reasoning written down. The decision:
  the **`Harness` row keeps its picker**, because switching harness is a real, already-shipped
  action and the picker is not the defect — the **server URL in that row is the defect**. So the
  endpoint descends to the new `Inference` row, where it is a property of a call rather than of
  an app, and `Agent` becomes strictly additive. Moving selection to `Agent` would have deleted
  a working control to fix a display collapse. Entry is immutable; a reversal is a new entry
  that supersedes it. **The panel itself is not built yet** — this records the decision only.
- **The state card no longer requires a click (`macapp/SeaStar/Views/EntityGraphView.swift`).**
  The readout was bound to `selected ?? hovered`, so with neither set there was no card at
  all and the graph opened looking empty — the "models and complexity around the active node"
  were only visible after clicking. `subject` now falls back to the active harness, so the
  endpoint/models/status state is on screen the moment the popover opens. Click and hover
  still override, so inspecting any other node is unchanged.
- **Idle harnesses now float by default (`macapp/SeaStar/Services/ServerController.swift`).**
  Latent harnesses were stored as an *enabled* set that defaulted to empty, so every
  installed-but-idle app was hidden until asked for — the same "boring" symptom from the
  panel side. The preference is now stored as a **hidden** set (`SeaStar.latentHarnessesOff`),
  so everything detected is in view until deliberately taken off. The old key held the
  opposite meaning, so reusing it would have inverted every existing choice; it is moved to
  a new key and the stale one is removed on launch. One-time consequence: a previously
  hidden app reappears on first launch after this change.
- **Test coverage for the new default** — `latentHarnessesDefaultToVisible` asserts
  detect-by-default, take-off, and restore.
- **Two new engine modules, and the bridge now carries what they find.** Both keys are
  optional additions and `schema_version` stays `1`, so an older app still decodes.
  - **`src/sea_star/harnesses.py` — latent harness discovery.** A *harness* here is anything
    Sea-Star can hand a model to, and an IDE that hosts its own agent loop is one; the vault
    host (Obsidian) deliberately is **not**, because it is the pool rather than a harness.
    `detect_latent_harnesses()` is a pure read of `/Applications`, `~/Applications` and any
    mounted volume's `Applications` — it never launches anything and never touches the
    network — returning known harness apps that are installed but *not* answering on a port.
    An app already answering is dropped so the graph never draws a double, first install
    wins, and the order is stable so the graph does not reshuffle between reads. The bridge
    emits it as `latent_harnesses[]` (`name`, `bundle_id`, `path`).
  - **`src/sea_star/agents.py` — agent discovery.** `AgentSpec(name, model, description)`
    read from Osaurus' declarative export, its live `~/.osaurus/agents/*.json` files, and its
    default agent file. Emitted as `agents[]` (`name`, `model`, `description`). **This is one
    adapter, not proof of generic agent-awareness** — the foundation's *agent-aware* rung is
    only reached for harnesses that can be *asked* (see its known debt), and this module asks
    a known app by reading its files.
  - **Known foundation violation, logged not hidden:** `harnesses.py` gates on
    `KNOWN_HARNESS_APPS`, so an unrecognised installed app is **silently skipped** rather
    than shown as an unknown/degraded harness — which is exactly the "name as a precondition"
    the foundation forbids. This is the deliberate next repair, because the new panel is
    where a degraded row becomes visible.
- **The sea-star was redrawn as anatomy, not a spiky polygon** (`SeaStarShape`,
  `EntityGraphView.swift`). Eight slender arms taper from a soft central disc to rounded tips,
  with webbing dipping between them — the leggy silhouette of a *Meridiastra* carpet sea-star
  rather than a squat five-point graphic. Every proportion is a fraction of the circumscribed
  radius, so one cut scales from a 17pt satellite up to the faint outline traced behind the
  whole pool, and a tiny seeded wobble in each arm's length and angle keeps the creature from
  reading as clockwork.
- **The pool gained living water** (`Views/GrainOverlay.swift`). The faint visual snow of a
  dark-adapted eye is laid over the void, so the space behind the starfield reads as water
  rather than a flat fill. The field is sparse and cool on purpose — it must never lift the
  pool's black or compete with a node for attention. Motion is the point, but not at the cost
  of accessibility: **Reduce Motion holds the grain still**, keeping the texture while
  dropping the drift.
- **The graph learned the two new entity kinds it was already being fed** — an **agent**
  (a persona in a harness) and a **latent** harness (installed, not answering on a port) — so
  both now draw as nodes instead of arriving in the report and vanishing. The graph is
  1,342 lines in the working tree against 800 at `74f63b9`.
- **`docs/one-pager.md`** states the product in a page: a private local AI assistant that
  lives in the person's own notes.
- Verified: `xcodebuild … build` succeeded; `xcodebuild … test` — 29 Swift Testing cases
  passing (8 suites), up from 28; `uv run pytest` → **76 passed**; `uv run ruff check .`
  → clean.

Harness: TRAE

Date: 2026-09-26

Summary of Changes:
- **The menu bar wears the detailed starfish, in both appearances (spec §7).** The glyph was a
  solid star; it now shows the same detailed starfish as the popover header, drawn by the one
  `AppIconMark` so the two can't drift. The four faces collapsed to a **single cut each**
  (`IconRoster`'s `asset`, the former `Face*Header`), rendered as a **template** on every
  surface, so the system tints it white on a dark menu bar and black on a light one and the fine
  line art stays legible either way. The bare cut read as a snowflake, so the mark now draws a
  **solid band partway out from the fuzzy centre** — a sea-star's body, with the ray tips still
  free — which keeps it from reading as either a snowflake's spokes or a cog's rim.
- **Both panels gained light and dark mode; the starfield stays dark (spec §7).** `Palette.swift`
  now splits into an **adaptive chrome** layer (`canvas`, `ink`, `inkMuted`, `logInk`, `logSurface`)
  that resolves per appearance — an `NSColor` dynamic provider keyed on
  `bestMatch(from: [.darkAqua, .aqua])` — and a **fixed-dark `pool`** that keeps the entity graph
  and its ink pinned dark. The graph on a pale canvas looked silly; it does not any more. Verified
  offscreen by sampling both appearances (canvas `#10131A`↔`#F7F3EC`, ink `#EDE3D2`↔`#1C1A17`,
  pool `#10131A` both).
- **The log's nudibranch strips are inset (spec §8.8).** The blue-white ribbons are floated on the
  log ground and pulled in from the edges to match the Start/Refresh controls, so they read as
  wiring *inside* the panel rather than its border; ground and ink adapt with the panel.
- **README polished.** Subtitle typo fixed ("One-click's ease" → "One click's ease"), Local-first
  and MCP badges added (all `?style=flat-square`), a new **At a glance** summary, the page count
  corrected to five, and the founder's closing note centered. Every fact and link unchanged.
- **Tests:** `xcodebuild … test` → **28 tests in 8 suites passing** (run twice across the icon and
  palette changes).

Harness: TRAE

Date: 2026-09-26

Summary of Changes:
- **The cockpit no longer runs off the bottom of the screen (spec §8).** The panel's height was
  only ever whatever its stacks added up to — an unbounded body plus a 150pt logs panel plus the
  header and the controls — so on a shorter display (or with the logs open) the bottom fell off
  the screen and was clipped. The whole cockpit is now capped to the screen's usable height
  (`NSScreen.visibleFrame` less a margin) and the middle section scrolls to fit, so every control
  stays reachable.
- **Operator instructions, in both tracks (spec §10 / T6.x).** New `docs/use-the-app.md`: the
  menu-bar Cockpit on one side (get it, open it, read what it found, choose, go) and the exact
  terminal equivalent on the other, headed by the parity table so no step exists on only one
  side. Linked from `docs/README.md` and the root `README.md`. It also records that macOS builds
  do **not** have to be shell-first (Xcode's own headless `xcrun mcpbridge`, §9.1) and that the
  `.icns` app icon (T4.4) is unnecessary while the app is `LSUIElement` (no Dock presence).
- **A no-go zone for every agent (AGENTS.md).** The founder's external drive — and any mirror of
  it — is off-limits: no reading, indexing, embedding, summarising or transmitting anything from
  it to a cloud or third-party model. Local-only at most, and only on an explicit written ask.

Harness: TRAE

Date: 2026-09-26

Summary of Changes:
- **The mode switch moved into the header (spec §8.7).** The cockpit's Graph/List choice was a text
  capsule sitting in the body; it is now two standard Apple symbols — connected points for the
  graph, a bulleted list for the rows — up with the **"ready"** pill and the gear, the active
  reading lit the way Apple lights a segmented control.
- **First launch asks how to open (spec §8.7).** Before a preference exists the popover shows a
  one-time chooser offering both readings (either will do); the answer is remembered in
  `UserDefaults` (`SeaStar.cockpitMode`) and the header icons swap it from then on. Until a choice
  is made the graph shows behind the question and neither icon is pressed.
- **Tests:** new `CockpitMode` cases (an unset preference opens the graph, a stored preference
  round-trips both ways, every reading carries a symbol, a label and a help line) —
  `xcodebuild … test` → **28 tests in 8 suites passing**.

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **A tip grows from the starfish (spec §8.7).** A short note now opens beside the active node in
  the graph, and tapping that starfish expands or contracts it. The rule is pure and unit-tested
  (`Models/HarnessTips.swift`): a harness the person has **never been on** gets a setting-up hint,
  other vaults nearby raise a **wrong-vault** nudge, and a known, ready harness gets a quiet
  **"connected — *n* models on offer"** line. Seen harnesses are remembered in `UserDefaults`
  (`SeaStar.seenHarnesses`, keyed by endpoint) and a fresh hint is dismissed with **Got it**, after
  which the note settles into the connected line.
- **The starfield moves (spec §8.7).** The entity graph is no longer a still frame. The orbs now
  drift on a slow per-node current (each entity's phase is hashed from its id, so nothing jitters
  between redraws), their glow breathes, and the vault↔harness connection **grows out of the
  vault** — the nudibranch ribbon is masked from the vault end and drawn on whenever the active
  harness changes, so the strip visibly *shoots out* at the thing it just connected to. Each orb
  also picks up the `caustics` Metal highlight used elsewhere. The whole pool stills under
  **Reduce Motion**.
- **The Logs toggle is findable.** The cockpit's Logs control was a bare mauve word nobody could
  spot; it is now a proper disclosure row — a rotating chevron, a terminal mark, the title and a
  live entry count, with a hover fill and a Show/Hide tooltip — so the panel is obvious to open
  and close.
- **Tests:** new `HarnessTips` cases (fresh hint, connected line, wrong-vault nudge, silence when
  not ready, idempotent remembering) — `xcodebuild … test` → **25 tests in 7 suites passing**.

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **Cockpit controls de-capsuled (spec §8).** The glass Start/Refresh pills are gone. Both are
  now plain mono words — small, toned down, the way Apple draws a text button — with **Start in
  the left corner and Refresh in the right**, and a clean band of space above and below the
  pair. A **blue-white nudibranch strip** sits above and below that band as the column
  reference the 3px bar was always meant to be.
- **Nudibranch strips land in the app (spec §7).** The founder's three 3px ribbons are now
  asset-catalog imagesets (`NudiBlueWhite`, `NudiGreenOrange1`, `NudiGreenOrange2`) rendered
  with `template-rendering-intent: original` so their gradients survive, and wrapped by a
  reusable `Views/NudiStrip.swift` (2px default, `expands` toggles full-width rule vs. fixed
  connection stroke).
- **Logs, kept short on purpose (spec §8.8).** A new `Services/LogStore.swift` pipes the
  engine's `stdout`/`stderr` into one durable, selectable log. The cockpit gains a collapsible
  **Logs** panel bordered top and bottom by the blue-white strip, inked in the matching blue
  (`logInkDark` / `logSurfaceDark`; a light pair is defined for an adaptive surface) in **SF
  Mono**. Settings gains a **Logs** section: a retention window (**Forever / 7 / 14 / 30 days**,
  default 14), an entry count, **Clear now**, and **Reveal in Finder**. Pruning runs on every
  write against `~/Library/Logs/Sea-Star/sea-star.log`, so nothing piles up on the disk the way
  most apps let it.
- **Entity graph — the "starfield" view (spec §8.7).** A segmented **Graph | List** toggle
  (List is the default) switches the popover between the familiar rows and a dark backdrop of
  glowing nodes: the vault on the left, harnesses down the right edge, the active harness's
  models ringing it, each in its own accent (`vaultGlow`/`harnessGlow`/`modelGlow`). Hovering or
  selecting a node reveals its name; tapping one drives the same `selectVault` /
  `selectHarness` / `selectModel` calls the list uses. The vault↔harness **connection** is drawn
  as a rotated nudibranch strip.
- **Tests:** new `LogStore` cases (the retention rule as a pure function — old lines dropped, a
  zero window keeps everything, the offered windows, plain-language labels) — `xcodebuild …
  test` → **20 tests in 6 suites passing**; `… build` → **BUILD SUCCEEDED**.

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **Right-click menu on the glyph — the "must have" (spec §8.6).** SwiftUI's
  `MenuBarExtra` renders the popover but exposes **no** right-click hook, so an accessory app
  had nowhere to put the standard app menu. The shell was rebuilt around AppKit: a new
  `@main enum SeaStarMain` starts `NSApplication` directly and hands off to a new
  `App/AppDelegate.swift`, which owns the `NSStatusItem` and shows an `NSMenu` on
  right-click (⌃-click too): **Check for Updates…**, **Settings…** (⌘,), **Help & Comments**,
  **Patchdog**, a disabled **Version × (build)** line, and **Quit Sea-Star** (⌘Q). Left-click
  still opens the cockpit popover. `App/SeaStarApp.swift` (the old `MenuBarExtra` shell) was
  deleted; the popover and settings are the *same* SwiftUI views, hosted in
  `NSPopover` / `NSHostingController`.
- **Settings window (spec §8.4).** A new `Views/SettingsView.swift` — the configuration
  surface the menu opens. Engine resolution + path, a **searchable** scrolling vault list with
  **Open folder… / Use detected vault**, harness/model pickers, an inline update check, and
  links (Help & Comments, Patchdog, repository).
- **GitHub Releases update check (spec §8.5).** New `Services/UpdateChecker.swift` asks the
  Releases API for `Roqett/Sea-Star`'s latest release and compares it to
  `CFBundleShortVersionString` as dotted numbers (a leading `v` and ragged segment counts are
  tolerated). Only a genuinely newer release offers to open its page; a failure says so
  plainly. `Support/Links.swift` is the one home for every external URL; `Support/AppInfo.swift`
  reads the bundled version/build.
- **Vault row can now search and adopt any folder (spec §8.1).** The popover's vault menu
  gained **Open folder…** (a folder picker → `SEASTAR_VAULT`), and its `PickerRow` no longer
  greys out when there is a folder entry to reach. `ServerController.clearVaultOverride()`
  returns to autodetection.
- **Model row follows the selected harness (spec §8.3).** `ServerController.modelOptions` now
  prefers `currentHarness.models` (falling back to `report.models`), so a Qwen model served
  only by oMLX appears the moment oMLX is chosen — the model that "wasn't coming up".
- **Popover scrolls (spec §8).** The header and the start/stop controls stay pinned; the
  detail body scrolls inside a `maxHeight: 320` region, so a long report no longer overflows
  the panel.
- **Tests:** new `Version`/`UpdateChecker.normalize` Swift Testing cases (newer wins; equal or
  older never does; leading `v` + ragged segments; tag normalisation) — `xcodebuild … test` →
  **16 tests in 5 suites passing**; `… build` → **BUILD SUCCEEDED**.
- **Real faces wired in (spec T4.3/T4.4 cuts).** The roster now points at the founder's
  actual artwork: each face ships two asset-catalog imagesets — `Face*Header` (40/80/120px)
  and `Face*MenuBar` (18/36/54px) — all black-ink-on-transparent, `template-rendering-intent:
  template`. The menu bar wears the solid silhouette (fine line art turns to grey mush at
  18pt); the popover header wears the full-detail cut, tinted by the face's accent. Both are
  templates because the ink lives in the alpha channel — that is what keeps the filigree
  readable on the near-black canvas, where the original black-on-clear art would vanish.
- **Header caustic shimmer (spec T4.5).** A new stitchable Metal shader
  (`Shaders/Caustics.metal`, wrapped by `Views/CausticsEffect.swift`) drifts a slow
  value-noise highlight across the header mark only. The highlight is gated by the artwork's
  own alpha, so the silhouette never moves — only the light travelling across it does — and
  the whole effect is disabled under **Reduce Motion**. Header-only: the menu-bar glyph stays
  a flat tinted glyph, where motion would just be noise.
- **`AppIconMark` renders both cuts as templates and sizes raster art explicitly.** Raster
  images ignore `.font`, so a `size` parameter now frames them (`resizable().scaledToFit()`),
  with the SF Symbol fallback kept behind it. `CockpitPopoverView` shares one `markSize`
  constant between the mark and the shimmer so the two can't drift apart.
- **Easter egg: the app has four faces and changes it on open/shut.** All four of the
  founder's icons are held in one roster (`Support/IconRoster.swift`) and the app wears one
  at a time. Every time the server is started or stopped it rerolls to a **different** face —
  never the one that just went away, which is the bit that makes the change read as
  deliberate. The face shows on **both** surfaces: the menu-bar glyph and the popover header
  (each face also carries its own glow colour, so the swap is obvious).
- **`ServerController` now owns `currentIcon`** and advances it on genuine start/stop
  transitions (and on a vault/model switch, which restarts). The controller is hoisted into
  `SeaStarApp` so the `MenuBarExtra` glyph is state-driven rather than a fixed symbol, and the
  popover reads the same instance.
- **Multi-harness detection (fixes the "Refresh missed my model" bug).** The engine's
  `detect_runtime()` probed `KNOWN_RUNTIMES` in order and adopted the **first** that
  answered, so if Osaurus (1337) was up it always won and shadowed oMLX/Ollama/LM Studio —
  the panel showed `osaurus · foundation` instead of the model being loaded elsewhere.
  `config.py` now exposes `probe_runtimes()`, which probes **every** live runtime
  concurrently (one `PROBE_TIMEOUT_SECONDS` budget via `asyncio.gather`) and returns a
  `RuntimeProbe` per live responder. `detect_runtime(probes=…)` and
  `load_config(probes=…)` reuse the survey, so single-runtime machines behave exactly as
  before while multi-harness machines see all of them.
- **Localhost port sweep (harness ports are not fixed).** oMLX's documented default is 8000,
  but the same person often runs a second copy on 8009 and other machines pick other ports —
  probing one address per harness still missed the model actually in use. `probe_runtimes()`
  now sweeps a standard set of localhost ports (`scan_ports()`: known-harness ports first,
  then extras like 8009/5000/9000) and names each responder by its self-reported
  `owned_by` when that is specific (oMLX says `"omlx"`), falling back to the port's known
  harness and then `"local"`. Generic owners (`library`, `user` …) are dropped so they don't
  masquerade as a harness. `SEASTAR_SCAN_PORTS` (comma-separated) replaces the set wholesale
  for an unusual setup. Still local-only and inside the same timeout budget.
- **The bridge now carries `runtimes[]` (spec §6).** `doctor --json` emits one object per
  live harness (`name`, `base_url`, `model`, `models`); the key is optional and
  `schema_version` stays `1` — the engine only ever adds keys, so an older app still decodes.
- **Cockpit: harness pick-list (spec §8).** The Harness row becomes a `PickerRow` when more
  than one harness is live and a plain `StatusRow` otherwise; the current choice is labelled
  `name · url` (an endpoint alone can't say which app answers on a shared port). Switching
  pins `SEASTAR_BASE_URL` + `SEASTAR_RUNTIME` — the same knobs the engine reads — and clears
  any model override, since the old model may not exist on the new endpoint.
- **Build note:** `.metal` files need Xcode's separately-downloadable Metal toolchain; on a
  fresh machine run `xcodebuild -downloadComponent MetalToolchain` before building.
- **Tests:** `IconRoster` (four distinct faces; a reroll never repeats the current face;
  a reroll with nothing showing still returns a face) plus the cockpit's opening face and
  the new `runtimes[]` decode — `xcodebuild … test` → **12 tests in 4 suites passing**;
  `… build` → **BUILD SUCCEEDED**; `Assets.car` (40 KB) and `default.metallib` (69 KB)
  confirmed in the bundle; app launches without crashing. Python: `pytest` → **51 passed**
  (multi-harness + sweep cases: every live server reported, scan order kept, a port-name
  fallback, an unlisted port named `local`, the `SEASTAR_SCAN_PORTS` override, a specific
  `owned_by` kept / a generic one dropped, a survey reused without re-probing, fails loud
  when nothing answers).

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **Cockpit: vault and model pick-lists (spec T3.2/T3.3).** The popover now offers the
  other Obsidian-known vaults (`vault.candidates`) and the endpoint's models (`models`),
  with the current choice shown in-row and checked in the menu. Switching re-runs the
  bridge with `SEASTAR_VAULT` / `SEASTAR_MODEL` pinned — the same knobs `resolve_vault`
  and `load_config` already read — so no engine change was needed. Choosing while the
  server is running restarts it so the new choice takes effect.
- **`EngineCommand.Invocation` now carries environment overrides**, threaded through
  `EngineClient.doctor` and `ServerController` and merged over the inherited environment.
  New Swift tests cover the threading and the empty-choice case (7 tests / 3 suites;
  `xcodebuild build` + `test` green).

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **macOS menu-bar app ("Cockpit") scaffolded** under `macapp/` — a SwiftUI
  `MenuBarExtra` app that wraps the engine with no terminal. XcodeGen project
  (`project.yml`), bundle id `UpPeriscope.Sea-Star`, deployment target macOS 26.0,
  files split `App/ Views/ Models/ Services/ Support/`. Builds, launches, and its four
  Swift Testing cases pass. The menu-bar mark is a placeholder SF Symbol until the
  founder's monochrome template icon lands (spec T4.3).
- **`doctor --json` reshaped to the full §6 bridge contract.** It now emits
  `schema_version` and a nested `vault { path, source, note_count, candidates }` object
  (was a flat `vault` string + `notes`), plus `server.state`. One JSON object, always,
  even on failure; human output stays the default.
- **Vault resolution moved into `config.py`:** `detect_vault_candidates()` (open-first,
  then most-recent) and `resolve_vault()` returning `(path, source)` with `source` ∈
  `env` / `toml` / `obsidian`, failing loud when none resolves — so the app can show
  *why* a vault won and offer the alternatives.
- **`tests/test_cli.py` added** for the JSON bridge (shape, fail-loud single object,
  human default), and `tests/test_config.py` extended with vault candidate/resolution and
  `allows()` coverage (spec T1.5/T1.6/T1.8). Engine: `ruff` clean, **40 tests** passing.
- **`macapp/SeaStar/Services/EngineClient.swift` + `Models/DoctorReport.swift`** — the app
  decodes the bridge object; it never scrapes human-formatted text.

Harness: TRAE

Date: 2026-09-25

Summary of Changes:
- **`doctor --json` — the app bridge contract.** `sea-star doctor` now takes `--json` and
  always emits one JSON object (vault, notes, runtime, base_url, model, models, bridged
  servers), even on failure, so a host app can poll it instead of scraping rich text. The
  human output is unchanged and still the default.
- **Curated bridged tools with `include` / `exclude`.** Each `[[mcp.servers]]` entry can
  carry `include` (allowlist; empty = every tool) and `exclude` (denylist; always wins).
  Filtering happens at connect time in `mcp_client.list_external_tools`, so the agent only
  ever sees a short, intentional tool menu.
- **README rewritten as two equal tracks.** A terminal-first path (available now) and a
  GUI-first path (coming), with a "Two ways to run it" parity table; dropped the marketing
  pull-quote and the `## The name` section; documented `include` / `exclude`.
- **mac-app spec → Revision 2, and now tracked.** Folded in the two-track
  instruction model (D9), the identity/naming decision (D10), the corrected Xcode toolchain
  (native `xcrun mcpbridge` path, §9.1), and the planned Omarchy (Arch Linux + Hyprland)
  port. The spec set (`spec.md`, `tasks.md`, `checklist.md`) is now committed under
  `.trae/specs/mac-app/` so it is versioned alongside the code; `.trae/*` is gitignored
  except `specs/`.
- **Added `docs/README_DRY.md`** — a spin-free reference doc (IS / DOES / SOLVES /
  DE-COMPLICATES) for cross-checking the Omarchy port with other models.
- **Naming settled: the repo stays at `Roqett/Sea-Star`.** Notarisation and the bundle id
  depend on the Apple Developer account, not on GitHub, so no org is required. All links
  were repointed from `UpPeriscope/Sea-Star` back to `Roqett/Sea-Star`; "Up Periscope"
  remains the product identity (licence + bundle id).

Harness: TRAE

Date: 2026-09-24

Summary of Changes:
- **Pointed every link at the renamed repository.** The GitHub repo is now `Roqett/Sea-Star`; clone URLs, `[project.urls]`, the docs and the changelog footer were updated to match, and the local `origin` remote was repointed.
- **Added oMLX to the runtime lists** (`README.md`, `docs/reference.md`, `docs/start-here.md`, `docs/troubleshooting.md`, `docs/README.md`, `AGENTS.md`) and to `KNOWN_RUNTIMES` in `config.py`, default endpoint `http://localhost:8000/v1`. It shares that port with vLLM; oMLX is probed first so autodetection labels the runtime `omlx`, and it needs no configuration.
- **README:** added a one-line warning to add `seastar.toml` to `.gitignore` when the vault is under version control, since the file can hold a real `api_key`.
- **Hero image:** replaced `assets/seastar_sf.png` with the updated artwork at `assets/sea-star.png` and repointed the README at the new path.

Harness: TRAE

Date: 2026-09-23

Summary of Changes:
- **Renamed the project to Sea-Star.** The display name, docs prose and ASCII art now read `Sea-Star`; the Python import package moved `src/seastar/` → `src/sea_star/`; the CLI command is now `sea-star`. The distribution name stays `seastar-mcp`, and on-disk identifiers stay `seastar.toml`, `.seastar/`, `~/.config/seastar/config.toml` and the `SEASTAR_*` environment variables, so existing setups keep working unchanged.
- **Toned down the README voice.** Plainer, more grounded language throughout; trimmed the wordplay that was getting in the way of the point.

Harness: TRAE

Date: 2026-09-23

Summary of Changes:
- `src/sea_star/mcp_client.py` — fixed `remote.inputSchema` → `remote.input_schema`. Under the pinned `mcp>=2.0` (installed: 2.2.0) the camelCase name no longer exists, so bridging any external MCP server (the "Way 3" capability) raised `AttributeError`. Verified against the installed library and re-run: ruff clean, 27 tests pass.

Harness: TRAE

Date: 2026-09-22 21:51 ACST

Summary of Changes:
- `docs/README.md` — new docs index; routes readers by who they are.
- `docs/start-here.md` — zero-jargon explainer: what Sea-Star is, what you need, the three moves.
- `docs/connect.md` — new connection guide: how to wire Sea-Star into Osaurus, Claude Desktop, Cursor and TRAE, and what to say to the host's agents.
- `docs/reference.md` — technical reference: CLI, MCP tools, config keys, runtimes, env vars, security model, invariants.
- `docs/troubleshooting.md` — failure modes and fixes, grounded in real errors.
- `docs/PROGRESS.md` — live build state and session handoff.
- `README.md` — added a Documentation section linking the docs index; linked Way 2 to the connect guide.
- `.gitignore` — added `INBOX/` so the document-staging folder never ships or commits.

### Added

- **Runtime-agnostic inference** (`inference.py`): talks the OpenAI-compatible
  chat-completions protocol over raw `httpx`, so Ollama, LM Studio, llama.cpp,
  MLX, vLLM and Unsloth Studio all work without a vendor lock-in.
- **Zero-config autodetection** (`config.py`): probes the six common local ports
  and adopts the first runtime that answers; fails loud when none do.
- **Obsidian vault autodetection** (`config.detect_vault`): reads Obsidian's own
  `obsidian.json` (macOS, Linux and Windows locations), prefers the currently-open
  vault, and falls back to the most recently used one — so `sea-star serve` works
  with no configuration at all.
- **Obsidian vault memory** (`vault.py`): scan, ranked search, read, write and
  append, with traversal-safe paths and `[[wikilink]]` citations.
- **Bounded agent loop** (`agent.py`): model turn → tool calls → observations →
  cited answer, capped by `max_steps`.
- **MCP server** (`mcp_server.py`): exposes `ask_seastar`, `vault_search`,
  `vault_read` and `vault_list` over stdio for Claude Desktop, Cursor, Trae, etc.
- **MCP client** (`mcp_client.py`): bridges external MCP servers (e.g. Obsidian
  ones) into Sea-Star's own tool registry under namespaced names.
- **CLI** (`cli.py`): `sea-star init | doctor | ask | serve | version`.
- **Factory protocol** (`AGENTS.md`): Tier 1/Tier 2 tripwires and core invariants.
- Test suite covering the vault, config resolution, tool registry, agent loop and
  MCP server surface.

### Changed

- **README focus** — added the "Osaurus + Unsloth Studio" setup recipe: Osaurus as
  the agent harness, Unsloth Studio as the OpenAI-compatible model server, Sea-Star
  as the shared private memory. The runtime-agnostic contract is unchanged.
- **Brand** — the octopus sign from The Sea Star (2289 3rd Street, Dogpatch, San
  Francisco) is now the repo's front image, with a short note on where the name
  comes from.
- Aligned the README's config file name, vault key and `[[mcp.servers]]` shape with
  the actual implementation.

### Fixed

- Corrected `agent.build_agent` to import `list_external_tools` (it previously
  referenced a non-existent `load_external_tools`, breaking every config that
  declared a bridged MCP server).

[Unreleased]: https://github.com/Roqett/Sea-Star/commits/main
