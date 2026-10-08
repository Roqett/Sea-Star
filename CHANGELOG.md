# Changelog

All notable changes to Sea-Star are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Harness: DeepSeek Harness

Date: 2026-10-06 19:50 ACDT

Summary of Changes:
- `src/sea_star/config.py` — `VAGUE_OWNERS` (`remote`, `local`, `host`, `server`, `api`) is treated as no owner at all, and `probe_runtimes` takes an `owners` map (port → the app holding it) to name an endpoint after the app that owns its socket. A server naming itself properly keeps its own name. Deliberately not merged into `GENERIC_OWNERS`: 1337's known port is Osaurus, so dropping `remote` outright would mislabel Atomic Chat as another product (D-015, D-018).
- `src/sea_star/cli.py` — the reconnaissance table is read the other way as well and threaded into the probe, so `Runtime:` reads `Atomic Chat -> http://127.0.0.1:1337/v1` instead of `remote -> …`.
- `macapp/SeaStar/Services/ServerController.swift` — `DialOption`; `harnessDial` (every known harness app, the attached one choosable, the rest switched off with their rung as the reason); `agentDial` (personas whose model nothing serves switched off); `servingPlacement(of:)` resolving a roster's qualified id (`omlx/qwen3-large`) against what endpoints actually list; `selectAgent` now cascades — the endpoint and the model follow a persona that can be honoured — and `selectHarness` points the engine at the servers the chosen app owns. `placement(of:)` resolves through the same rule, so the sentence and the dial cannot disagree.
- `macapp/SeaStar/Views/CockpitPanel.swift` — `DialRow`, a menu over everything that exists including the entries that cannot be chosen (ticked for the one in use, greyed with its reason for the rest), replacing the Harness `StatusRow` and the Agent `PickerRow`; endpoint labels gain their port.
- `macapp/SeaStar/Support/Strings.swift` — the words a switched-off dial entry needs: the reason for an unknown rung, "nothing is serving its model", and the `name — reason` join.
- `macapp/SeaStarTests/EntityGraphTests.swift` — a suite for the panel's dials: the harness roster and its rungs, a persona nothing serves (the engine's real Patchdog case) being switched off rather than moving something, the cascade moving endpoint + model, an unserved persona moving nothing, and the sentence and the entry agreeing for every persona. The fixture gained a fourth agent and a qualified model id. 95 Swift tests in 17 suites.
- `.trae/specs/mac-app/spec.md` — §8.2/§8.3 rewritten: the Harness row is the roster dial, and an endpoint is labelled by the app that owns its port, with its port.
- `DECISIONS.md` — D-018.

Harness: DeepSeek Harness

Date: 2026-10-06 19:40 ACDT

Summary of Changes:
- `macapp/SeaStar/Views/EntityGraphModel.swift` — a sixth kind, `.core`: one `seastar` node at the middle of both drawings, excluded from `majors`, never `isLive`. It is wired to the vault it lives in, the hosts driving it and the one endpoint it reads through, and `standingEdges` names the wires the whole-pool reading draws (the ring's bindings plus the hub's; a satellite's spokes stay for the focus reading) (D-017).
- `macapp/SeaStar/Services/ServerController.swift` — `endpoints(ownedBy:)`, the reverse of `bundledOwner(of:)`: the endpoints a named app's own process was observed to hold a port for, restricted to the ones that actually answered as model servers.
- `macapp/SeaStar/Views/EntityGraphView.swift` — the single vault→endpoint ribbon becomes a `wireLayer` over `standingEdges`: green-and-orange with the D-002 crawl while something live is on the wire, blue-white when it is only a stated binding, Sea-Star's own wires drawn heavier. The core is placed at the centre of the layout, sized above the vault, and `layout(in:)` is internal so the arrangement can be checked without a window.
- `macapp/SeaStar/Views/GraphScene.swift` — the deep colours a wire by the same liveness facts (`GraphScenePlan.isLive`) and draws Sea-Star's heavier (`touchesCore`), so flying between the two readings cannot change which connections look live.
- `macapp/SeaStar/Support/Palette.swift` — `coreGlow` (mauve): the palette's structural voice, so the hub is not the vault's bone.
- `macapp/SeaStar/Support/Strings.swift` — the hub's own card: Observing / No endpoint answering, Driven by, Reading through, Answering now.
- `macapp/SeaStarTests/EntityGraphTests.swift` — a suite for the hub (one core, off the ring, at the middle of both readings, never live, wired to the right three things, its card honest), the ownership wire pinned on both an attached and an unattached app, the wire set pinned, and the plan's live/`core` wire facts pinned. 90 Swift tests in 16 suites.
- `.trae/specs/mac-app/spec.md` — §8.7 rewritten where it still described the old drawing: the ring of majors, the hub at the centre, the real node colours, and what a wire may claim.
- `DECISIONS.md` — D-017.

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
- `macapp/SeaStar/Views/CockpitPanel.swift` — the `Working now` band is rebuilt as one honest sentence. It had two liveness bars, a row that changed its own label with server state, a host row duplicating the Harness row above it, and a two-paragraph evidence line. Now it is one status word — Live / Running / Idle — and one sentence: the endpoint answering and the model it serves.

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

Harness: DeepSeek Harness

Date: 2026-10-06 14:55 ACDT

Summary of Changes:
- `src/sea_star/config.py` — `read_omlx_loaded_model()` reads oMLX's own admin route for the model that is actually `loaded` (the chat `llm`, not its built-in `markitdown` helper), and `probe_runtimes()` moves it to the front so `RuntimeProbe.model` is *observed* rather than guessed. OpenAI's `/v1/models` lists what an endpoint offers and has no field for which model is loaded, so believing its first entry named a model oMLX was not running — the cockpit read "answering as Dirk-Qwen3.8" while oMLX was serving MiMo-V2.6.
- `tests/test_config.py` — tests for the reader (picks the chat model over the helper, `None` when nothing is loaded or the route is absent) and for the probe preference, plus an autouse fixture that keeps every probe test off the machine's real oMLX admin route.
- `macapp/SeaStar/Views/EntityGraphView.swift` — the pool's hover is one cursor hit-test (`hitNode`) instead of a per-node `.onHover`: the topmost node (the last-drawn agent) was swallowing every hover and staying lit wherever the pointer sat, so the cursor never highlighted what it was over. The vault→inference ribbon now crawls — drawn at twice the link's length and slid along a one-length track, driven by the frame clock the pool already runs on, which is the "scale ×2 / 8pt sweep" D-002 promised and the graph never got. Node labels and the tip note counter-scale and counter-turn against the pool's zoom and turn, so their glyphs are never resampled by the canvas transform that was making them soft beside the crisp card and list.
- `macapp/SeaStar/Views/GraphReadoutCard.swift` — fact values wrap instead of truncating in the middle ("Stops when oM-el lives here" was a clipped claim, which is worse than a taller card); the card widens 240 → 268 to suit.
- `macapp/SeaStarTests/EntityGraphTests.swift` — four tests pinning the hover rule: the node under the cursor, empty water, an overlap resolving to the node drawn on top, and the hit's outer bound.

Harness: DeepSeek Harness

Date: 2026-10-06 15:10 ACDT

Summary of Changes:
- `macapp/SeaStar/Views/HarnessTray.swift` — new: the harness roster moves into a QuickTime-4-style **drawer** at the foot of the graph (D-014). One centred control slides it out; an Aqua grip — two thin rules on a recessed capsule — closes it; the tray grows out of the panel's own lower edge rather than opening a window or a popover. No `NSDrawer`, no deprecated API.
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — graph mode hosts the drawer in place of the always-visible `HarnessVisibilityList`, and **an open drawer is paid for out of the pool**: `graphHeight` gives up 214pt while it is open, so the panel's capped height is unchanged and the whole roster stays on screen (the first build simply grew the panel and cut the last row in half). `isTrayOpen` lives here for that reason.
- `macapp/SeaStar/Support/Strings.swift` — the drawer's own strings (`trayTitle`, `trayHelp`, `trayCloseHelp`), so no user-facing copy is hardcoded in the view.
- `.trae/specs/mac-app/spec.md` §8.7 — records the drawer, its grip, and the pool-gives-way height rule.
- `DECISIONS.md` — D-014, with the height rule and the reference it is built from.

Harness: DeepSeek Harness

Date: 2026-10-06 15:50 ACDT

Summary of Changes:
- `src/sea_star/harnesses.py` — **CLI harnesses are found while they are running.** Some harnesses ship no `.app` at all — OpenCode, Goose and the DeepSeek Harness run as bare binaries — so the `ps` scan, which looked only for `.app` bundles, could never see one: a demonstrably open OpenCode read as latent, or as nothing. New `KNOWN_HARNESS_COMMANDS` + `running_command_harnesses()` report them with the rung they have actually reached (`running`), under a namespaced `cli:<name>` identity that can never collide with a bundle id. A running CLI harness also stands in for its installed desktop sibling, so one product cannot appear twice.
- `src/sea_star/config.py` — `probe_runtimes(extra_ports=…)`: the ports reconnaissance **observed** listening are probed as well as the fixed sweep list. A harness puts its own model server wherever it likes — Atomic Chat's Apple foundation server answers on 3355, which the sweep never looked at — so a live endpoint was sitting in Sea-Star's own socket table and was never spoken to. The caller threads the ports in; `config` still only asks a port, it does not survey the machine.
- `src/sea_star/cli.py` — `_build_report` reads the socket table once, gives its loopback ports to the probe, and reuses that same reading for the bridge's `listening` list (it had been read twice).
- `macapp/SeaStar/Views/HarnessTray.swift` — the drawer tab is a **grip, not a labelled bar**: the name and the chevron are gone (what it does is the hover label now) and the three rules are drawn directly at 34×2 instead of taken from `line.3.horizontal`, whose own lines are short and thin and read as a menu icon rather than the QuickTime tab's wide grooves.
- `tests/test_harnesses.py` — four tests pinning the CLI family (reported running, standing in for the desktop sibling, dropped when attached, never invented when stopped), and `_detect` now pins `commands` so no test reads the machine's real process table.

Harness: DeepSeek Harness

Date: 2026-10-06 16:30 ACDT

Summary of Changes:
- `macapp/SeaStar/Views/CockpitTray.swift` — **new, and replaces `HarnessTray.swift`.** The drawer is generic now: it holds whatever belongs to the reading it sits under, which is what let the header shed a whole pair of buttons. `TrayChoiceRow` gives a drawer a labelled row of mutually exclusive choices, so a two-way setting can live at the foot of the reading it affects.
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — the header carries **three** controls instead of five: the mode pair and Settings. The **depth** choice moved into the graph's drawer, beside the roster it already held, and the **layout** choice into the text reading's own drawer — so a control for a reading you are not in is no longer sitting in a header both readings share. `depthToggle` and `layoutToggle` are deleted. The title and subtitle are pinned to one line: the narrow text reading was rendering the app's own name as "Sea-" / "Star", which reads as a broken title rather than a title.
- `macapp/SeaStar/Support/Strings.swift` — the drawers' titles (`Harnesses`, `Reading`, `Depth`, `Layout`) and a hover label that takes the drawer's name, so the closed ledge stays an unlabelled grip.

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

Harness: OpenCode

Date: 2026-10-07 12:31 ACDT

Summary of Changes:
- `macapp/SeaStar/Services/ServerController.swift` — restored the Swift build: `FileManager.default.currentDirectoryURL` is not a real property and stopped the entire Mac app from compiling, so the tree and the running binary had drifted apart. Now `URL(fileURLWithPath: FileManager.default.currentDirectoryPath)`. Adds `HarnessRung.isUp` — "a process owns it, or something answered in its name" — distinct from `isAttached`, which stays "driving Sea-Star now".
- `macapp/SeaStar/Views/EntityGraphView.swift` — a harness that is **up but not attached** now gets its own visual state instead of the dead grey a dormant install gets (D-020). The 2D pool gave every non-`isLive` node `glow = 0`, which drew a running IDE pixel-identical to an app that never launched, undoing the distinction the engine had correctly reported. It now takes a steady `0.34` glow at radius 5, presence `0.72`, with its glyph lit. Steady and never pulsing: the breath stays reserved for `isLive`, because being up is not the same as carrying work and foundation §2 forbids claiming a rung not reached. `.present` harnesses are unchanged.
- `macapp/SeaStar/Support/Strings.swift`, `Views/CockpitPanel.swift`, `Views/CockpitPopoverView.swift` — `Stack`/`Chain` renamed **Facts**/**Path** (D-019), named for what they communicate rather than how they are laid out. Both readings stay; the toggle moves out of the drawer into the header as two SF Symbols with hover text, shown only in the list reading. The text reading's drawer is removed — layout was its only content. The graph drawer is untouched.
- `PanelLayout` cases renamed `.facts`/`.path` while their **raw values stay `"stack"`/`"chain"`**, so a stored preference from before the rename still resolves. The case names are the truth; the raw values are a migration.
- `macapp/SeaStarTests/DoctorReportTests.swift` — the panel-layout suite follows the rename; the stored-preference round-trip test now pins that the old raw values still resolve.
- `macapp/SeaStarTests/EntityGraphTests.swift` — the existing "never flattened to one grey state" test now also asserts the rung distinction survives into `isUp`, and that being up is never mistaken for being attached.
- `DECISIONS.md` — D-019 (Facts and Path, and the toggle's move to the header) and D-020 ("up but not attached" is its own visual state).
- `docs/WORKSPACE-IMPLEMENTATION.md` — recorded as incomplete rather than shipped: the fifth row detects against the process's current directory, which is meaningless for a menu-bar app outside a project, and it is not in the foundation's four rows. Left in the tree, not displayed as agreed.

Harness: OpenCode

Date: 2026-10-07 14:05 ACDT

Summary of Changes:
- `macapp/SeaStar/Views/EntityGraphView.swift` — focus views no longer flatten liveness: the focus edge layer drew *every* wire blue-white, so clicking a star made a live connection and a dormant one indistinguishable — the exact confusion the whole-pool reading had already solved. It now reads the same `isLive` facts and draws live wires green-orange at 3pt, resting ones blue-white at 2pt.
- `src/sea_star/providers.py` — **new.** Reads what a harness *declares* it gets models from (`~/.config/opencode/opencode.json` and the same shape for five other harnesses). A configured provider holds no socket, so this is the one link of the cascade no port probe could ever have shown — the harness-config reader recommended in D-015/D-017/D-018 and flagged as the blocker across four handoffs. Derived fields only `(provider, base_url, model)`; API keys and the raw document never enter the result, and the dataclass is frozen.
- `src/sea_star/providers.py` — an **MCP server URL is never read as a model route.** The first implementation accepted any URL and reported `https://mcp.exa.ai/mcp` as OpenCode's model provider on this machine, because the live `opencode.json` declares two MCP servers and no model at all. `_is_model_route` admits only an inference surface (`/v1`, `/v2`, `/models`, `/completions`, `/embeddings`, or a bare loopback port) and rejects `/mcp` paths. This is D-010's lesson again — *the presence of a URL is not the shape of a claim* — and the stale premise in four handoffs is corrected: they cite a `"model": "atomic/Dirk-…"` entry that no longer exists.
- `src/sea_star/cli.py` — `providers[]` on the bridge (additive; `schema_version` unchanged; always one JSON object). An older engine yields `[]`.
- `macapp/SeaStar/Models/DoctorReport.swift` — `ConfiguredProviderInfo` and the `providers` key, decoding an older engine's absence as "this build did not look" rather than "no harness uses a model".
- `macapp/SeaStar/Services/ServerController.swift` — `declaredProvider(forHarnessNamed:)`, matching the engine's short key (`opencode`) against the graph's display name (`OpenCode`) in both directions, space/dash-insensitively. A miss returns `nil` rather than borrowing a neighbour's claim.
- `macapp/SeaStar/Views/EntityGraphModel.swift` — a harness node's subtitle names what it is *configured for* ("Configured for atomic · atomic/Dirk"), and a local declaration resolves to an endpoint **only when Sea-Star can already see that endpoint answering** — so a wire never points at a node that was never drawn. A cloud route or an unseen port stays a label. Never liveness: the node's rung and `isLive` are untouched.
- `tests/test_providers.py` — **new,** 15 tests. The negative cases carry the weight: an MCP URL is never a model route, malformed JSON degrades to absent rather than failing, an unlisted harness is unread rather than invisible, and a config full of `apiKey`/`authToken`/`password` yields a claim containing none of them.
- `macapp/SeaStarTests/EntityGraphTests.swift` — 7 new tests for the declaration's honesty contract (never live; never borrowed; cloud and unseen-port claims stay labels), plus the shared fixture gains OpenCode and TraeCode.
- `docs/web-canvas-3d.md` — **new.** The browser 3D canvas investigated and measured rather than argued: `3d-force-graph` 1.80.1 is MIT and viable, **364 KB gzipped** against a 4.8 MB bundle (~7%), but WebKit is a new framework dependency, the model must be serialised across a rendering seam, and its nodes are **spheres** — the sea-star glyph is the identity this app is built on. Verdict: not yet; fix the crowding natively, and prefer the split panel.
- `DECISIONS.md` — D-021 (a configured provider is a rung-0 declaration; an MCP URL is never a model route).
- `CHANGELOG.md` — appended a **second** entry for this session rather than editing the earlier one, per the append-only rule.
- Counts: **179 Python tests**, **102 Swift tests in 18 suites**, ruff clean.

Harness: OpenCode

Date: 2026-10-07 14:35 ACDT

Summary of Changes:
- `docs/brand.md` — **new.** The brand and style reference this repository never had. Assembled from records that already existed and had drifted apart: the palette from `Palette.swift` (the code, which is authoritative), the Carpet Sea Star rationale from the handover, the voice from `foundation.md`. Covers the name and identity split (`Roqett/Sea-Star` the repo, **Up Periscope** the licence/bundle id), why the eight-armed *Meridiastra calcar* is the creature, the ten hex values with **the meaning each one carries** (plum is API inference because it is the only node that leaves the house; teal is local inference; bone is the vault so it does not compete with a model's green; mauve is Sea-Star and is deliberately not bone), the two-layer adaptive-chrome/fixed-dark-pool rule, type, motion discipline, the marks, and a voice section with a words-we-don't-use table. Records that the source art is eight-pointed and must not be "fixed", and that `assets/sea-star.png` predates the current icon art.
- `site/index.html` — **new.** A single-file static landing page: hero, a real example answer with its citation, the trilemma the product solves, the cascade as four steps, the cockpit in three readings, runtimes, install, FAQ, an honest status line. Styling is inline and uses the brand hexes as CSS variables, with `prefers-color-scheme` light and dark, `prefers-reduced-motion` honoured, and every colour used for the meaning `brand.md` assigns it. **Three screenshot placeholders** carry HTML comments with the exact capture procedure and what each image must show — no image is claimed that has not been taken.
- `docs/TECHNICAL.md` — **new.** The technical overview for a developer who is not the founder. Architecture and module map, then the substantial part: the capability ladder as a table with how each rung is obtained, the degradation contract and its enforcement in tests, how "no name is ever a precondition" is actually implemented (vocabulary over lists, roles over names, degrade-don't-vanish) with **the three category errors it has caught**, recognition without launching anything, the symmetry clause *and where MCP cannot help and why*, the privacy envelope with both derived-fields-only modules, the testing strategy, a failure-mode table, six items of known debt, and the bridge contract with a note on the stale `server.state`.
- `README.md` — documentation table gains the technical overview and the foundation, and the count is no longer hardcoded ("Five pages"). App section corrected from "in build / coming" to built-and-refining, with the unreleased/private status stated where a reader would otherwise assume otherwise. The two-front-doors table now reflects the app as it is, including the Facts/Path rows, the Logs panel and the log path. Project layout updated with the eight modules that did not exist when the list was written, plus the `macapp/` tree. Screenshot placeholder block added with the capture procedure.
- `docs/README.md` — index gains two doors (technical overview, brand & style) and the documentation map is brought up to date, including `one-pager.md`, `brand.md`, `TECHNICAL.md`, `web-canvas-3d.md` and `site/`.
- Verified: HTML tag balance checked programmatically; code fences balanced in all three markdown files; no unescaped ampersands outside code spans. **179 Python tests, ruff clean** — no code changed.

Harness: OpenCode

Date: 2026-10-08 23:05 ACDT

Summary of Changes:
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — **you can get back out of the deep reading.** The founder: *"I still can't alternate between this 3D test and the original"*. Flat/Deep was buried in a tray at the foot of the graph, so the deep view was a dead end and getting back meant finding a hidden drawer — the second time in one session he could not find a control he was entitled to (the first was Facts/Path as bare symbols). It is now in the graph's own header, icon **and** word, visible only in the reading where it means something. The tray keeps the roster, which genuinely belongs out of the way.
- `script/shot.sh` — **new.** Captures a reading as a PNG, opening the cockpit if closed. Exists because an agent could build a reading and never *see* it, which the founder hit exactly: *"I would take a screenshot of but I can't click back to that from this window either"*. Two ways of opening the cockpit were tried and **rejected on evidence**: a distributed-notification hook the app would listen for built and launched but never fired (`notifyutil -p` left `cockpitOpen` at 1 while an AppleScript click took it to 0), and a URL scheme, which is permanent public surface wanting a real design. The hook was **removed rather than shipped** — a door that silently does not open is the exact failure this project exists to avoid. This host now has assistive access granted, which earlier in the project it did not.
- `macapp/SeaStar/App/AppDelegate.swift` — `SeaStar.cockpitOpen` is now written `false` at launch. It survived a relaunch from the previous session and reported "open" for a popover that did not exist, which is how `shot.sh` came to photograph the desktop instead of the app. A flag that outlives the thing it describes is the same class of lie this app exists to avoid.
- `macapp/SeaStar/Views/GraphScene.swift` — **labels restored, and it was my own regression.** Scaling captions to half the node radius made every name invisible and the room a set of unidentifiable stars. Caught by capturing the reading and looking at it, not by any test — nothing here can assert that a caption is legible to a person. Now sized against the node's own radius with a floor.
- `macapp/SeaStar/Views/GraphScene.swift` — **wires are hairlines**, down from 1.6/0.9 to 0.42/0.24. They were three times the weight of a star's own arms and read as poster paint; the founder's *"still nothing like the nice fine detail and clarity of our 2D version"*. The core/ordinary distinction is kept because that *is* information, just far finer.
- **Reverted, unproven:** widening the pool to radius 260 and pulling the camera to 760 was tried to spread the crowd and made it *worse* — the room stopped being crowded and became a distant clump, because the crowding had not gone, only shrunk. The real cause is the satellite pull, which draws models and personas onto their anchor and packs several bodies into one space. That is a layout decision, not a number, so the experiment was backed out rather than tuned blind and the reason recorded at the declaration.
- Verified: **102 Swift tests in 18 suites**, ruff clean, **197 Python tests**. **The deep reading is still not where the flat pool is** — the glyphs, the wires and the labels are right, and the third axis now carries the rung, but the arrangement needs a proper layout pass on the satellite pull before it can be called finished.

Harness: OpenCode

Date: 2026-10-08 22:55 ACDT

Summary of Changes:
- `macapp/SeaStar/Views/GraphScene.swift` — **the spheres are gone, and that was the whole problem.** The founder's screenshot showed what he called "big old blobs in that wacky pop art thing, unlike the beauty of our 2D version, which is perfect". Each node was a solid emissive `SCNSphere` with the sea-star art on a quad floating in front of it, so the thing on screen was **the back of a coloured ball seen through a star-shaped window**. The flat pool has no sphere at all — it draws the creature directly — and that is precisely why the 2D looks right and this did not. The node *is* the glyph now: the same art at the same weight the 2D uses. What remains that the 2D cannot offer is the part the 2D cannot have — a third axis that carries the rung, and a camera you can turn. The roster does not stop being the same roster because the room is real.
- `macapp/SeaStar/Views/GraphScene.swift` — **the camera was far too close, and the giant blob was not special, merely near.** It sat at z=240 while the pool's radius is 120, so the closest node stood 120 units from the eye and the furthest 360: a 3:1 size disparity that made the near side of the ring enormous and unreadable. Moved back to 430, which roughly halves the disparity and lets the height axis be read instead of being shouted over by scale.
- `macapp/SeaStar/Views/GraphScene.swift` — **labels were sized in world units, not points.** `SCNText` at 11pt against a node whose glyph is ~16 units across made the name nearly as large as the thing it named — the oversized type across the whole screenshot. Now scaled to half the node's own radius, so a caption reads as a caption at any pool size and stays quiet rather than shouting across the room.
- Verified: **102 Swift tests in 18 suites** pass, ruff clean. Awaiting the founder's eye — the three changes were each read off his screenshot rather than chosen in the abstract.

Harness: OpenCode

Date: 2026-10-08 22:35 ACDT

Summary of Changes:
- `macapp/SeaStar/Views/EntityGraphModel.swift` — **the deep reading now means something.** The founder's verdict on the 3D room: *"being able to just rotate the thing around looks like a novelty that is trivial and that will only produce scorn in the tech community."* Diagnosis confirmed it in the code: depth was pure decoration, because the majors sat on a ring whose `z` was `sin(angle) × radius`, so turning the room showed the same arrangement from another side.
- **The third dimension now carries the foundation's own ladder** (`rungHeight`): what is answering stands highest, what is merely installed sits low. Turning the room *reads* the machine — how much of it is working — instead of re-showing a picture. `nil` (vault, model, persona) stays at the neutral plane, because those are not rungs.
- **Height, not depth along z, and the distinction is load-bearing.** The first attempt pushed nodes along z and broke `majorsRingThePool` — a test stating a real guarantee: the majors' horizontal distance from the centre is exactly the radius, *"which is what makes the shape learnable: the same roster always opens the same way round, and you learn where things are."* On a horizontal ring, z **is** a radial axis, so pushing along it would have made the pool unlearnable to pay for legibility. Height is perpendicular to the ring, so the guarantee survives untouched and the pool gains an axis it did not have. The failing test was treated as the specification, not the obstacle.
- `macapp/SeaStar/Views/GraphScene.swift` — **the neon is gone**, which is what made the room *"wacky blob pop art from the 80s"*: HDR, bloom, pushed contrast and raised saturation were all on together. Depth now comes from height and fog instead. Fog is load-bearing too — without it every body sits at the same apparent distance and a tilted pool reads as a flat blob from every angle, and it pushes an installed-but-off harness visibly to the back, which is exactly what the height axis says and what additive glow was faking.
- `macapp/SeaStar/Views/GraphScene.swift` — **D-020 applied to the deep reading**, closing a loose end open since the morning handover. The 2D pool gave a running-but-unattached harness a steady glow; the 3D room still gave it nothing, and it still carried the floating liveness bars the founder asked to remove **twice** — the two readings disagreeing about the same fact, which is the exact failure the shared arrangement exists to prevent. Up-but-not-attached is now a still unlit torus ring: lit, never pulsing, because the breath is reserved for work and being up is not the same as carrying it. Live nodes keep the breathing ribbon.
- Verified: **102 Swift tests in 18 suites** pass, ruff clean, **197 Python tests** pass. Two build errors were caught by compiling rather than reading (a `Float`/`CGFloat` mismatch and a `SCNBillboardConstraint.freeAxes` call that does not exist in this SDK); the ring-radius failure was caught by the test suite. **Not yet judged by eye** — the founder has the app open on the deep reading and needs to say whether it looks like this product now.

Harness: OpenCode

Date: 2026-10-08 22:05 ACDT

Summary of Changes:
- `script/phone_preview.py` — **new. A screen on the phone, over the tailnet.** The founder asked for the one door this project lacked: a way to *see* a build rather than be told a build is fine, because he works away from this machine and needed it by 7:30am. Screen Sharing would do it, but needs a VNC client, a full desktop session and an interactive password prompt — the wrong shape for a glance between two jobs. This serves one picture of the cockpit over Tailscale, which is already installed and already carries this Mac and the founder's phone.
- **Two decisions that are load-bearing, not incidental.** It binds to the **Tailscale address only**, never `0.0.0.0`: a screen is the most private thing this Mac owns, so the surface is reachable from the founder's own devices and nowhere else, and Tailscale's membership *is* the authorisation — no second lock to forget on a phone at 6am. Verified: the service is refused on loopback and answers only on the tailnet address. And it **prefers the cockpit's own window**, because a full-desktop capture works and would also hand over every other window, sticky note and notification on the machine; the whole-screen fallback is a deliberate last resort that the page *names*, so a blank panel is never ambiguous between a broken app and a closed one.
- **Nothing is written to disk and nothing is logged.** Each request captures, serves and discards, so the history of what was on screen does not outlive the glance.
- The page auto-refreshes every 4s, because the real question on a tractor is "is it still alive" and answering it should not need a second tap; it says which capture you are looking at and when it arrived. A failed capture returns the reason as plain text rather than a broken image.
- Two bugs found and fixed while proving it, both caught by running it rather than reading it: an unescaped `{}` dict literal inside an f-string (SyntaxError on launch), and an em-dash in an HTTP header value, which is latin-1 and raised `UnicodeEncodeError` — so header values now carry no typographic punctuation.
- **Note:** this reaches only devices on the tailnet. Remote Login and Screen Sharing are both still **off**, and enabling them needs sudo this agent does not have — a founder action in System Settings → General → Sharing.

Harness: OpenCode

Date: 2026-10-08 21:55 ACDT

Summary of Changes:
- `src/sea_star/agents.py` — **one agent, however many processes it is made of** (`detect_agent_instances`, `AgentInstance`). The founder's framing: *"they are still agents, even if they don't have names — that's what I'm talking to."* A desktop agent is a dozen processes (app, CLI, helpers, renderers) and counting them calls one conversation eight agents, so a candidate whose ancestor **of the same product** is also a candidate is a helper and is dropped. What survives is the root: one root, one agent. Two OpenCode instances the person is actually talking to therefore stay two agents, which is the case a naive collapse would have hidden. Product matching reads the `.app` bundle in the path, falling back to the executable stem, so no product name is hardcoded.
- `src/sea_star/agents.py` — **an unnamed running agent is still reported.** No persona file, no name, and it appears. Declining to show work in progress because no definition exists is the same blindness the name-less CLI had.
- `src/sea_star/agents.py` — **two roles recorded separately rather than forced into one category** (`is_attached`, `serves_models`). Running this live caught the mistake before it shipped: the first candidate set included `oMLX`, which is an inference *server*, not an agent. Filing a model server as an agent is exactly the error that made the cockpit unreadable once already, and Atomic Chat genuinely does both — drives Sea-Star *and* serves the model it drives it through. Forcing either label loses half the truth, so both facts are kept and the caller decides the wording.
- `src/sea_star/agents.py` — `_instance_workspaces` reads each instance's working directory in one batched `lsof`, so "which project is this agent pointed at" is read rather than assumed; a pid whose directory cannot be read is absent rather than guessed.
- **5 new tests**, including one asserting a dozen-process app collapses to one, one that a CLI beside an app stays its own agent, and one that a pure model server is flagged rather than either hidden or mislabelled.
- Verified: **197 Python tests** (was 192), ruff clean. Live on this machine: 5 candidate processes → 5 instances, with oMLX marked *serves models* and Atomic Chat marked *drives Sea-Star* — each fact attached to the thing it is true of.

Harness: OpenCode

Date: 2026-10-08 21:20 ACDT

Summary of Changes:
- `src/sea_star/agents.py` — **the Agent row no longer reports one empty cupboard as the whole house.** The roster was read from a single harness's own store, so "no roster found" meant *I checked one place and it was empty* — while the person could have a dozen agents written as files. Two families are now read and **unioned**: a harness's own store, and **agent files as a shape** (a Markdown file with a delimited header carrying `name`, `description`, `model`, in a directory named `agents`). The directory name is the convention — the JSON store already uses it — so the *layout* is the discriminator and **no product name appears in the code**: a harness invented tonight is read because its files have the shape. First-match-wins is gone, because returning the first non-empty source reported a roster that existed and silently omitted the rest, which is the same lie as reporting none and harder to spot.
- `src/sea_star/agents.py` — `candidate_agent_dirs` takes a `workspace`: where a harness is pointed decides which `agents/` directories it can reach, so project agents are found without asking anyone. The home sweep is one level of dot-directories only — personal agents, not a crawl of the disk.
- `src/sea_star/agents.py` — the header reader recognises plain `key: value` scalars and **deliberately stops there**. `tools`, `effort` and `mcpServers` are not read because nothing acts on them, and reading less is what keeps this from becoming a second implementation of somebody else's config format. No YAML dependency added. An unterminated header, a README, or a file with no name yields no agent rather than a phantom one; a quoted value reads clean.
- **8 new tests**, including one proving a dot-directory nobody in this codebase has heard of (`.vibeweaver/agents/`) is read purely by its layout, one proving a populated store cannot hide the agent files, and one that a README in an `agents/` folder is not an agent.
- Verified: **192 Python tests** (was 184), ruff clean. Live on this machine: `~/.claude` exists but holds no `agents/` directory, so the empty roster is a true reading of both families rather than one — which is exactly the honesty the row existed for.

Harness: OpenCode

Date: 2026-10-08 20:50 ACDT

Summary of Changes:
- `macapp/SeaStar/Services/ServerController.swift` — **stopped the two-second flash.** The founder's report: with the cockpit watching continuously, every node blinked every two seconds. Cause: `adopt` assigned `report` unconditionally, and the graph's model is a computed property rebuilt from the controller on every render pass — so each poll threw the whole graph away and restarted the pulse animation from zero. `adopt` now returns `Bool` and **only assigns when the reading actually differs** (`DoctorReport` is already `Equatable`). Everything downstream is now a function of real change rather than of the clock. This matters beyond irritation: a rapid full-brightness flicker is a genuine hazard for photosensitive users.
- `macapp/SeaStar/Services/ServerController.swift` — `logs.append` in `refresh` is now gated on that same change, so the Logs panel no longer gains an identical "refresh ·…" line every two seconds and scrolls for as long as the cockpit is open.
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — the header status dot no longer reads `isRefreshing`. That was invisible when the cockpit read once and became a colour flip twice a second once it watched; a background poll is not a "checking" state and must not be drawn as one. `isRefreshing` still governs the Refresh button's enabled state, where it belongs.
- Verified: **102 Swift tests in 18 suites** pass, ruff clean, 184 Python tests pass.

Harness: OpenCode

Date: 2026-10-08 18:45 ACDT

Summary of Changes:
- `macapp/SeaStar/Views/CockpitPopoverView.swift` — **the cockpit now watches the machine.** It re-read every 2s while open (`watchTheMachine`, `watchInterval`), replacing a single read at open time. The gap this closes: the cockpit claims to tell the truth about this machine *now*, and one read made that false the moment anything changed — launching a harness, quitting one, or a model server coming up all left the panel describing a machine that had stopped existing. Cancellation is the off-switch (`.task` tears it down on close), so a closed cockpit costs nothing. Also: the Facts / Path switch now shows **its words** (`▤ Facts` / `⇣ Path`). As bare SF Symbols it was unreadable in use — the founder could not tell which reading was which without hovering each one, so the control failed at the only job it has. Hover text still carries the longer explanation.
- `src/sea_star/harnesses.py` — **new family: a CLI recognised by what it does, not what it is called.** `serving_harness_processes` reports the process holding any loopback port already proven to answer with a model list. This closes the headless-CLI gap: a bare CLI agent has no bundle, no `Info.plist`, and — outside `KNOWN_HARNESS_COMMANDS` — no handle at all, so `running_command_harnesses` matching on process name left every agent invented after that dict was written invisible *permanently*. For a headless agent that is not a gap in coverage but the entire mechanism failing. A port that answers as a model server is evidence needing no name, which is the foundation's "no name is ever a precondition" applied to a process table, and it is the same principle `recon.MODEL_VOCABULARY` already documents in its own source. The six known names stay as an additive hint, never a gate. A serving port with no known owner is skipped rather than guessed at.
- `src/sea_star/cli.py` — wires the new family into the bridge, threaded by hand from `probes` (the only module allowed to speak HTTP, and the only source of the "answers with a model list" proof) and `listening_services()` for the owner. `service.app_name` is preferred over `service.process` so an owned port reads as `oMLX` rather than `python3.11`.
- `tests/test_harnesses.py` — **5 new tests**, including one asserting a CLI named `nightfall-agent` is found while a test asserts it is *absent* from `KNOWN_HARNESS_COMMANDS` (the hint-is-not-a-gate rule, stated as an executable claim), plus no-guess-on-unowned-port, no-contribution-without-proof, and one-product-one-row. That last test initially asserted the wrong winner and was corrected: a running process outranks its installed app, which is the pre-existing OpenCode rule, not a new one.
- Verified: **184 Python tests** (was 179), ruff clean. Live on this machine with TextEdit launched as a control — it correctly does **not** appear, and `python3.11`/`ControlCenter`/`rapportd` do not leak in despite 9 loopback listeners. **102 Swift tests in 18 suites** pass.

Harness: OpenCode

Date: 2026-10-08 09:15 ACDT

Summary of Changes:
- `docs/HANDOVER-2026-10-08.md` — **new.** The cold-start handover for the session the founder asked for, superseding the 2026-10-02 snapshot in `NEXT-SESSION.md` (which is kept and relabelled as history). Nine sections: the state in one screen; how the session started and what the review found; the founder's decisions; what was built, with the three findings from the provider reader that matter more than the feature; **what is uncommitted and the four suggested commits**; what needs his eyes versus what is verifiable from code; loose ends; the traps; and the single next step. Records that the app was **not running** at handover and must be started before any visual check, and that `docs/WORKSPACE-IMPLEMENTATION.md` contradicts his decision not to display the Workspace row.
- `docs/README.md` — the "start here" door now points at the 2026-10-08 handover, with `NEXT-SESSION.md` explicitly relabelled as the superseded 2026-10-02 snapshot kept for history.
- No code changed. **179 Python tests, 102 Swift tests in 18 suites, ruff clean.**
