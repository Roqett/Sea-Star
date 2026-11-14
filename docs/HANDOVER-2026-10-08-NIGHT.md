# Session handover — 2026-10-08, night

Cold start. Everything below is verified; nothing is assumed. Supersedes nothing —
`HANDOVER-2026-10-08.md` is the morning session and still stands as history.

---

## ⚠️ Do this first

**`http://100.126.11.98:8766` — the founder's phone screen.** A live picture of his
Mac, auto-refreshing every 4s, reachable only from his phone over Tailscale. He had
never seen the app run and asked for exactly this. **Try it on the phone first thing
and tell him whether it is usable or clumsy** — he was explicit that the session had
run long and this is the one open thread he wants closed.

Serve it with `python3 script/phone_preview.py` (binds the tailnet address only).

**He also has the OpenCode app on his phone.** If that already reaches the Mac, this
may be redundant for *working* — it is only for *seeing*. Ask which he actually uses
rather than assuming.

## Two toggles only he can flip

System Settings → General → Sharing → **Remote Login** and **Screen Sharing**. Both
are off; port 22 and 5900 are not listening. No agent here has sudo. With both on he
has a terminal and full control from the tractor.

---

## State

| | |
|---|---|
| Branch | `feat/macapp-cockpit`, **39 commits** ahead of `main`, 2 unpushed |
| Tree | **Clean.** First clean tree since 6 October |
| Tests | **197 Python**, **102 Swift in 18 suites**, ruff clean |
| App | Built and running |
| Repo | Still **private**. Flipping it is his call |

Unpushed: `d9ff1fd` (phone preview) and `b818941` (ruff). Push is his word.

## What today fixed

Every one of these was found by him looking at a running app, not by reading code.

- **The build didn't compile** — `currentDirectoryURL` is not a real property.
- **The cockpit never listened** — it read the machine only on open, on Refresh and
  after a setting changed. Working in a harness left the panel describing a machine
  that had stopped existing. Now it re-reads every 2s while open, and stops dead when
  closed.
- **Then it flickered** — every node blinked every 2s, because the report was assigned
  unconditionally and the graph model rebuilds on every render pass, restarting the
  pulse. **A rapid full-brightness flicker is a genuine photosensitivity hazard.** A
  reading is now adopted only when it *differs*.
- **Facts and Path were unlabelled** — bare SF Symbols; he could not tell them apart
  without hovering each. They carry their words now.
- **Headless CLIs were permanently invisible** — recognition matched on process name
  against six hardcoded names. For a bare CLI that list was the *only* mechanism able
  to see it. Now a CLI is the process holding a loopback port answering as a model
  server (D-025).
- **The Agent row reported one cupboard as the whole house** — it read one harness's
  private store and called the result "you have no agents". It now also reads agent
  files *by shape*, and unions both families (D-023).
- **Agent instances** — one agent is one root process; helpers collapse into it;
  unnamed running agents still count (D-024).

## Decisions recorded today

**D-022** Workspace row **removed**; a workspace is where a harness is pointed.
**D-023** Agents read by shape. **D-024** One agent, one root process.
**D-025** CLIs by what they serve. **D-026** The cockpit watches; redraw only on change.

`docs/WORKSPACE-IMPLEMENTATION.md` was rewritten — it had described a failed
experiment as shipped, and documented a fourth hardcoded name list.

## The hardcoded-lists problem, stated once

There were **four** of them: six CLI names, seven runtime names, eight workspace
markers, one harness's agent store. The CLI one was the worst — the comment
justifying it was **an agent's rationalisation, never a founder decision**. Two are
now gone. `KNOWN_RUNTIMES` remains but is only a **naming and ordering** hint;
discovery already sweeps every observed port, so it is not a gate.

## Open, none blocking

1. **Wrong model name.** The Inference row says `Dirk-Qwen3.8-27B`; the truth is
   `MiMo`, which oMLX reports as `loaded: true`. The chosen server (Atomic Chat,
   1337) has no way to say which model it serves, so `RuntimeProbe.model` falls back
   to `models[0]` — a guess. **Proposed wording, not yet approved:** *"Doesn't say
   which model it's serving — 7 on offer."*
2. **Server priority** is still a fixed order, which is why Atomic beat oMLX. Should
   prefer whichever server can honestly say which model it serves. Same root cause.
3. **Panel wording.** His words, his call. He asked to see exact words first.
4. **`site/assets/` is not committed** — `S_S_1.png` is the correct eight-armed glyph
   but nothing references it; `sea-star.png` is 5.2 MB and `brand.md` records it as
   predating the current icons. The page therefore shows stale art.
5. **Spec `D3`** still locks the graph to a `WKWebView` while the same spec and the
   shipped code describe native renderers. One line settles it. Founder-only — do not
   edit unprompted.

## House rules that bit tonight

- Verify with a **control**, not an assertion. TextEdit launched as a false-positive
  test; a CLI named `nightfall-agent` asserted found *and* asserted absent from the
  list.
- **Run the thing.** Two bugs shipped past reading and were caught by executing: an
  f-string syntax error and a latin-1 header. Also the first agent-instance run caught
  a category error (oMLX filed as an agent) before it landed.
- Commit messages must describe what actually shipped. A first attempt swept 37 files
  into one commit with an engine-only message; undone and redone by path.
- Push, merge and making the repo public need his explicit word.

## Next step

He opens `http://100.126.11.98:8766` on the phone and says whether it is usable. Then
the model-name wording, then commit and push.