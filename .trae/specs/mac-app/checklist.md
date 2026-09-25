# Acceptance checklist — Sea-Star macOS menu-bar app

Verification for [spec.md](file:///Users/lono/Random_MCP/theSeaStar/.trae/specs/mac-app/spec.md).
`[ ]` = unmet, `[x]` = met.

## North star

- [ ] The founder completes **detect → choose → start → stop** without ever opening a terminal.
- [ ] A terminal-comfortable user completes the same flow entirely from the CLI — no second-class path.
- [x] The engine's test suite stays green (`uv run pytest` ≥ 27 passing, `uv run ruff check .` clean).

## Bridge

- [x] `sea-star doctor --json` emits JSON and exits `0` on this machine (interim shape, §6).
- [x] The §6 GUI fields are present: `vault.candidates`, `vault.source`, `server.state`,
      `schema_version` (T1.6).
- [x] Human `sea-star doctor` output remains the default (no `--json`).
- [x] Missing vault/runtime → non-zero exit with a populated `error` field.
- [x] JSON keys are frozen and carry `schema_version`.
- [x] The GUI never parses human-formatted text.
- [x] Scoped tool surface: `include`/`exclude` are enforced and surfaced by `doctor --json` (D8).
- [x] Tool scoping has tests (`allows()`: allowlist, denylist, precedence) (T1.8).

## Cockpit

- [x] Menu-bar item is present and its label is ≤ ~30 characters.
- [x] Popover shows the resolved vault, the answering harness, and the current model.
- [x] Vault pick-list offers the other Obsidian-known vaults.
- [x] Model pick-list is populated from the endpoint.
- [x] Start/stop works and server state is visible at a glance.
- [x] App launches with no vault configured → clear, non-crashing guidance.
- [x] Easter egg: all four faces are held in one roster and the app rerolls to a different
      face on server start/stop — never repeating — on both the menu-bar glyph and the
      popover header (T4.7). Now wearing the founder's **real** art (T4.3/T4.4 cuts).

## Design

- [x] Canvas uses `#10131A`; accents drawn from the Carpet Sea Star palette.
- [x] Liquid Glass via `glassEffect` on the control layer only; `GlassEffectContainer` +
      `glassEffectID` used for grouped glass; not overapplied.
- [x] Menu-bar icon is a **monochrome template image**, correctly tinted in light/dark.
      *(Real solid silhouettes cut from the founder's art — `Face*MenuBar` imagesets with
      template rendering intent, spec T4.3.)*
- [ ] App (Dock) icon is layered/coloured; distinct from the menu-bar icon.
      *(In-app header/menu-bar art wired; the founder's Icon Composer `.icns` export is still pending — T4.4.)*
- [ ] Sea-star mosaic motif is subtle, not a full-screen carpet.
      *(Partial: header caustic shimmer landed (T4.5); broader motif pass still to come.)*

## Graph

- [ ] codebase-memory index re-run; embedded graph shows current paths (no `src/seastar/...`).
- [ ] `WKWebView` displays `http://localhost:9749` restyled to palette.

## Release

- [ ] Local build runs on the founder's machine.
- [ ] Bundle id is `UpPeriscope.Sea-Star`; Team shows `NICHOLAS BLADES BICKFORD` (D10).
- [ ] (Later) Signed + notarised + stapled build opens cleanly on a machine that didn't build it.

## Instructions (dual track)

- [ ] **GUI-first** track exists and is complete: zero-terminal install → launch → detect →
      choose → start → stop (T6.1).
- [ ] **Terminal-first** track exists and is complete: every GUI action has a CLI equivalent
      (T6.2, §10.2).
- [ ] The two tracks are in sync — same steps, same order, neither second-class (T6.3).
- [ ] Docs state the native, headless Xcode MCP path; no stale "shell-first / iOS-only"
      claim remains (T6.4, §9.1).

## Docs

- [x] [PROGRESS.md](file:///Users/lono/Random_MCP/theSeaStar/docs/PROGRESS.md) updated; handoff note appended.
- [ ] No third-party reference photos committed to a public push.
