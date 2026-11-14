# Sea-Star — next session starts here

Written 2026-10-02 at the end of a long session, at the founder's request, because he
wanted a clean restart. **Read this top to bottom before touching anything.** It is the
state of the world, the loose ends, and the to-do list. If you only read one section, read
[*Start here, right now*](#start-here-right-now) and [*The to-do list*](#the-to-do-list).

---

## 1. What Sea-Star is, in one paragraph

A free (MIT), local-first, runtime-agnostic **MCP server that is also an MCP client**. It
reads an Obsidian vault as its memory, answers with citations, and hands any agent app one
tool — `ask_seastar`. It also consumes other MCP servers as its own tools. Repo
`Roqett/Sea-Star` (the founder's personal account), mirrored to Codeberg as
`Touretro/theSeaStar`. "Up Periscope" is the product identity in the licence and bundle id,
not a GitHub org.

Two documents are binding and are not duplicated here:
**[`docs/foundation.md`](foundation.md)** (the rules — chiefly *"no name is ever a
precondition"*) and **[`AGENTS.md`](../AGENTS.md)** (how to work with the founder). The
engineering decisions of the last three sessions are **[`DECISIONS.md`](../DECISIONS.md)**,
append-only, D-001 to D-013.

---

## 2. Start here, right now

**Nothing is answering locally.** As of this handover `sea-star doctor` fails: oMLX is not
running and nothing is listening on any model port (only the DeepSeek Harness GUI on 19387).
The app is *correctly* reporting that — it is not a bug. To bring it live:

```bash
open -a oMLX          # or Osaurus / Unsloth / anything OpenAI-compatible
uv run sea-star doctor   # should print Ready
```

**The state of the repo is clean and green:**

| | |
| --- | --- |
| Branch | `feat/macapp-cockpit` (32 commits ahead of `main`) |
| Working tree | **clean** — nothing uncommitted |
| Remotes | pushed to `origin` (GitHub) **and** `codeberg`, both in sync |
| Draft PR | [#2](https://github.com/Roqett/Sea-Star/pull/2) open, 130 files, **not** merged |
| GitHub repo | **still private** — flipping it public is the founder's call |
| Python | 153 tests pass, `ruff check .` clean |
| Swift | 79 tests in 14 suites pass, `xcodebuild` clean |

**What the founder sees when he clicks the star:** graph mode, flat depth, stack layout,
onboarding already marked as seen (`SeaStar.onboardingShown = 1`). If you change his
defaults for testing, change them back or say so.

**He has already answered two onboarding questions** — in `~/.seastar/register.json`:
`claude` and `gemini` state directories are **not harnesses**. That is a decision about the
product, not a mis-click: see loose end 6.

---

## 3. The idea the app is built on — get this and everything else follows

**The cascade.** One request path: **Vault → Harness → Agent → Inference.**

- **Vault** — the notes. Everything is connected to it; that hop is never in question.
- **Harness** — the app driving Sea-Star (an IDE, a chat app, another agent harness).
- **Agent** — a persona inside a harness, riding a model.
- **Inference** — where that model comes from: an endpoint on this machine, or an API.

The founder's words: *"you pick the harness, then you pick the agent, then you pick the
inference that agent is on and you know where it's at — whereas on our graph we can
immediately see that graphically as well. This is the whole concept of the app."*
(D-013.)

Every surface renders that one path, from one rule:
the **text panel** as four rows, the **graph** as wires, and the **MCP answer** as text.
The utility flows downstream: a harness attached over MCP can ask where a model comes from
because the cockpit already knows.

---

## 4. What exists now — the architecture in plain terms

**Engine (Python, `src/sea_star/`)** — the part that was already done and stayed green:

- `config.py` — finds the vault, probes local runtimes, resolves the endpoint. **The only
  module allowed to speak HTTP to a model.**
- `vault.py` — the only module that touches vault files. `agents.py` reads rosters.
- `inference.py` — the only path to a model. `tools.py`, `agent.py`, `mcp_server.py`.
- `mcp_server.py` — the tool surface: `ask_seastar`, `vault_search`, `vault_read`,
  `vault_list`, and **`machine_report`** (new this session).

**New this session, and the heart of it:**

- **`recon.py`** — reconnaissance. Reads this machine's own **process and socket tables**
  (the same ones Activity Monitor reads), and attributes every listening port and live
  outbound connection to the `.app` that owns the process tree. Triggered, never watching:
  it has no timer, no thread, and keeps nothing between calls. It reports:
  `listening`, `model_like` (proved vs merely suspected), `outbound`, and the **behaviour
  ledger** — one row per app: what it serves, whether it uses its own server, what it
  reaches for outside. Observations only; there is deliberately **no field for motive**.
- **`register.py`** — the ask-once store at `~/.seastar/register.json`. Discovery proposes,
  the person answers once, the answer is remembered **by bundle id or path, never by display
  name**. Browsers and OS components are barred by *declared role* (a browser claims
  `http`/`https` in its own Info.plist; `/System/` is the OS), never by a list of names.
- **The cascade rule, twice, in the same words** — `ServerController.placement(of:)` in
  Swift and `agents.placement()` in Python. Three honest cases: served by a running
  endpoint / built for a provider that is up but not serving it / offered nowhere.

**The app (`macapp/`, XcodeGen + SwiftUI + AppKit) — three surfaces, one job each (D-012):**

1. **The cockpit popover** — the everyday reading, and only that. Header (icon, status pill,
   graph/text switch, contextual depth or layout switch, gear, settings) · **list mode** =
   the four rows + `Working now` · **graph mode** = the starfield with the float/take-off
   list beneath it · logs · Start/Refresh. A hard height ceiling with one scroll region, so
   the header can never be pushed off the screen again.
2. **The onboarding window** (`OnboardingView.swift`, "Set up Sea-Star…" in the menu bar) —
   the behaviour ledger, the full register with its evidence, and the graph's cast. Opens
   once on first launch; reachable from the menu and from Settings afterwards.
3. **Settings** — the knobs, now wearing the house style (canvas, ink, accent bars, mono
   headings) instead of a generic grouped Apple form.

**The graph has two renderers** behind `SeaStar.graphDepth`: the flat 2D pool
(`EntityGraphView`, default) and a 3D SceneKit room (`GraphSceneView`). Both read the same
`EntityGraphModel`, so they cannot disagree about what is true.

---

## 5. What was decided in the last three sessions

Read `DECISIONS.md` for the reasoning; this is the index.

| | |
| --- | --- |
| D-001/D-002 | The panel splits Vault / Harness / Agent / Inference; two windows, two axes, one shared model. |
| D-003 | The comparison modes (`Both`) retire; one reading per axis. |
| D-004 | **A harness is the app driving Sea-Star; an endpoint is inference.** `Kind.inference` added, `Kind.latent` deleted; the rung is drawn. |
| D-005 | Reconnaissance is **triggered, never watching**; recognition is by vocabulary and register, never a list of app names. |
| D-006 | The register: one question per thing, remembered by identity. |
| D-007 | An inbuilt model server belongs to its app, and the dependency is stated. **MCP cannot discover inference**; the OpenAI `/v1/models` schema can. |
| D-008 | The behaviour ledger: one app with no stake reports what every interested app is doing. |
| D-009 | **Traffic never raises a question**; browsers and OS components barred by declared role. |
| D-010 | **A port is not a server** — only an answered probe may be stated as serving. |
| D-011 | Ship via Developer ID + notarised DMG; the Release configuration refuses to build without a real signature. |
| D-012 | Three surfaces, one job each; hard height ceiling; Settings in the house style. |
| D-013 | **The cascade is the spine**; every surface renders it from one rule. |

---

## 6. Loose ends — every one I know about

Ordered by how much they will bite.

1. **Nothing is answering locally.** oMLX is not running (see §2). The app correctly says so.
   *Action:* start a local runtime. Not a code problem.
2. **The engine is not bundled inside the app.** The DMG contains the menu-bar app and
   nothing else; on this machine it finds the repo and `sea-star` on `PATH`, on a stranger's
   Mac it would find nothing. **A notarised DMG is not yet worth distributing and no amount
   of signing fixes it.** `script/release.sh` prints this on every run. *Action:* vendor the
   engine into `Contents/Resources/engine` and point `EngineCommand.resolve()` at the bundle
   before `PATH`; ideally bundle a relocatable Python.
3. **No signing identity on this machine** (0 identities). The *request* is prepared:
   a private key and CSR sit in `~/.seastar/signing/`, and the key is imported into the login
   keychain and trusted by `codesign`. To finish: developer.apple.com → Certificates →
   Developer ID Application → upload `developerID.certSigningRequest` → download the `.cer`
   → `security import <file>.cer -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign`
   → `export SEASTAR_TEAM_ID=…` → `./script/release.sh`. **The founder says the membership is
   in place**; the certificate was simply never created on this Mac. He has since said we are
   *not* doing this yet because the app isn't finished — so treat it as parked, not lost.
4. **GitHub is private and PR #2 is unmerged.** Both are the founder's calls.
5. **`docs/README_DRY.md` contradicts itself.** It says it is *"git-tracked locally / on
   Codeberg, not pushed to the GitHub repo"* — but it **is** tracked and was committed to
   both (commit `7828ada`). *Action:* either correct the claim or untrack the file.
6. **The CLI-agent-state family is producing noise the founder has already dismissed twice.**
   `agent_state_dirs()` offers `~/.claude`, `~/.gemini`, `~/.ollama` as candidates; he has
   answered **not-a-harness** for the first two. *Action:* once he answers the third, retire
   the family (or downgrade it to a label rather than a question). Evidence beats design
   intent here.
7. **The agent roster is one source.** Everything the Agent row shows comes from Osaurus's
   roster, and the app says so honestly. The cascade's second hop — *this harness's own
   crew* — is not built. *Action:* teach the engine to read each detected harness's roster.
8. **The 3D renderer is still an open design question** (SceneKit room vs a bundled offline
   web canvas at codebase-memory quality). The founder leans browser. This is the single
   biggest thing standing between the app and looking as good as it should. The 3D room is
   also the only remaining user of the nudibranch liveness bar.
9. **Stack vs Chain for the text panel** — undecided; currently `stack`.
10. **The ledger has no memory.** *"Which app reached outside last Tuesday"* needs a record
    over time, which is exactly what the no-background-monitoring rule forbids. A genuine
    fork in the road, and the founder's call.
11. **An inbuilt model server may be unauthenticated** and reachable by any local process.
    Whether the cockpit should say so is a privacy decision, not a bug. His call.
12. **The workspace family needs a path.** `.trae/`, `AGENTS.md` and friends are the only
    evidence family that proves *use* rather than installation, but the cockpit passes no
    project path — only the CLI does (`sea-star harnesses --workspace`).
13. **`mcp_configs` reports presence only**, never the tool names inside another app's
    config. Naming them would honour the symmetry clause; it is a decision about reading
    another app's configuration.
14. **Xcode and non-beta OpenCode have no reliable fingerprint.** They are covered by the
    seed table and nothing else. This is the honest residue the register exists for.
15. **The `KNOWN_HARNESS_APPS` seed table** is demoted to a hint but still exists. Revisit
    pruning it once the register has been in use for a while.
16. **Nothing visual has been verified by eye** for the last three changes (the three-surface
    restructure, the rebuilt `Working now` band, the onboarding window). The sessions' models
    had no image input; everything was verified through the window system and by scanning
    screen pixels. **The founder's eyeball pass is outstanding.**
17. **Small debris:** the `Metal` toolchain flakiness (see the traps below) and the `/tmp`
    screen captures this session left behind. Nothing in the source tree is dead: the
    constants left over from the retired pieces (`LivenessBar`, the old `Working now`
    strings) were checked and pruned before this handover.

---

## 7. The to-do list

**For the founder to decide (an agent should not choose these):**

1. **Flip the repo public?** Draft PR #2 is ready to review either way.
2. **The renderer:** fix the SceneKit room, or move to a bundled offline web canvas.
3. **Stack or Chain.** Retire the loser.
4. **The ledger's memory:** live-only, or a record kept over time (a values question).
5. **Say the unauthenticated-endpoint fact in the cockpit, or not.**
6. **Harness → agent scoping:** approve the engine work to read every harness's roster.
7. **Notarisation:** when the app is finished enough, create the certificate (2 clicks) and
   run `./script/release.sh`. Parked deliberately for now.

**For an agent, in the order I would do them:**

1. **Get it live and look at it with the founder.** Start oMLX, open the cockpit, read the
   four rows, pick an agent and read the placement line, then the same fact on the graph.
   Nothing else matters until the founder has seen the three surfaces he has not seen.
2. **Wire the workspace family into the cockpit** (loose end 12) — it is the only family that
   proves use, and it is one parameter away.
3. **Retire or downgrade the CLI-state family** (loose end 6) once he answers `ollama`.
4. **Bundle the engine** (loose end 2). The last real gap before a DMG is worth giving anyone.
5. **Harness roster reading** (loose end 7), once approved — the cascade's missing half.
6. **Fix `docs/README_DRY.md`'s claim** (loose end 5), and prune the seed table
   (loose end 15).

---

## 8. Traps a new session will otherwise walk into

- **The Metal toolchain.** `xcodebuild test` can fail with
  *"cannot execute tool 'metal' due to missing Metal Toolchain"* even though the toolchain is
  mounted and `xcrun --find metal` resolves. It bit us twice. **Retry once — it passed on the
  retry both times.** If it persists: `xcodebuild -downloadComponent MetalToolchain`.
  `SeaStar/Shaders/Caustics.metal` is the file it is compiling, and a plain `build` usually
  succeeds from cache where `test` recompiles it.
- **New Swift files need `xcodegen generate`.** The project is generated from `project.yml`;
  adding a file without regenerating means it is silently not compiled.
- **System Events cannot see the cockpit popover.** `count windows of process "Sea-Star"`
  returns 0 while the popover is visibly open. Do not conclude it is broken. The app's own
  state is readable: `defaults read UpPeriscope.Sea-Star SeaStar.cockpitOpen` (1 while open).
- **The star's screen position.** Accessibility reports the status item at
  about `(1441, 3)`; the app's own `convertToScreen` reports `(8, -11)` and is wrong.
  Trust the AX position. A synthetic click tool lives at `/tmp/mouse`
  (`/tmp/mouse click <x> <y>`) and works.
- **No vision on several models.** If the session's model cannot read images, verify UI
  changes by measuring — window frames via `osascript`, state via `defaults`, and colours by
  converting a `screencapture` to BMP and scanning pixels. That is how this session found the
  floating liveness bars.
- **Never add an app name to a list to make something appear.** That is the trap the whole
  architecture exists to escape (foundation's lead clause, and D-006/D-009).
- **The founder's no-go zones** (AGENTS.md): his external drive and any mirror of it are
  off-limits; nothing from there is read, indexed or summarised. The `/Volumes` sweep was
  deliberately removed from `harnesses.py` this session.
- **Changelog convention:** `Harness:` and `Date:` only — never a model identifier or routing.
  This session switched models four times and could not have recorded them honestly, which is
  precisely why the rule exists.
- **Commit and push**: the founder gave the word for this branch. Ask before anything that
  publishes (making the repo public, a release).

---

## 9. The one next step

**Start a local model, open the cockpit with the founder, and read the three surfaces
together.** Everything built in the last three sessions — the cascade, the register, the
ledger, the three-surface split — has been verified by tests and by measuring the screen, but
not once by eye. His pass is the only thing that can say whether it is right.
