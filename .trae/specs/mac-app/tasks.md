# Tasks — Sea-Star macOS menu-bar app

Ordered task list for [spec.md](file:///Users/lono/Random_MCP/theSeaStar/.trae/specs/mac-app/spec.md).
Status auto-updates as work proceeds. `[ ]` = pending, `[~]` = in progress, `[x]` = done.

## Phase 0 — Decide & align

- [x] **T0.1** Confirm app location → `macapp/` subfolder (D6).
- [x] **T0.2** Confirm bridge command and shape → `sea-star doctor --json` (D7, §6).
- [ ] **T0.3** Founder reviews this spec set.
- [ ] **T0.4** Confirm the **two instruction tracks** (D9): GUI-first (zero terminal, default)
      and terminal-first (CLI parity). Both first-class; neither "advanced".

## Phase 1 — Bridge (engine, keep tests green)

- [x] **T1.1** Add `--json` to `doctor` in [cli.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/cli.py#L65-L127); keep human output the default.
- [x] **T1.2** Emit the §6 object. The final shape is live: `schema_version`, `ready`,
      `version`, nested `vault {path, source, note_count, candidates}`, `runtime`,
      `base_url`, `model`, `models`, `server.state`, `servers`. Tested (T1.5).
- [x] **T1.3** Map fill-in logic to existing internals: vault order in [load_config()](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/config.py#L219-L231), `detect_vault()` in [config.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/config.py#L177-L207), `KNOWN_RUNTIMES`.
- [x] **T1.4** Fail loud: non-zero exit + populated `error` when no vault/runtime.
- [x] **T1.5** Add tests for the JSON surface; run `uv run ruff check . && uv run pytest`. → `tests/test_cli.py`; 40 tests green.
- [x] **T1.6** Extend the bridge with the GUI fields (§6): `vault.candidates`, `vault.source`,
      `server.state`, `schema_version`; reshape `vault` into an object.
- [x] **T1.7** Scoped tool surface (D8): `include`/`exclude` on `[[mcp.servers]]`, enforced at
      connect time in `list_external_tools()` ([mcp_client.py](file:///Users/lono/Random_MCP/theSeaStar/src/sea_star/mcp_client.py)); surfaced by `doctor --json`.
- [x] **T1.8** Add tests for tool scoping (`allows()`: allowlist, denylist, precedence).

## Phase 2 — Scaffold the cockpit

- [x] **T2.1** Create the SwiftUI project (Swift Package or `.xcodeproj`) under `macapp/`
      (D6). Bundle id `UpPeriscope.Sea-Star` (D10); Interface SwiftUI,
      Language Swift, Testing System **Swift Testing** (plain — not XCTest UI Tests).
      → XcodeGen `macapp/project.yml`.
- [x] **T2.2** Structure folders: `App/`, `Views/`, `Models/`, `Services/`, `Support/`.
- [x] **T2.3** `MenuBarExtra` scene with a compact popover; short label (≤ ~30 chars).
- [x] **T2.4** `Services/` CLI client: run `sea-star doctor --json`, decode into `Models/`.
      → `EngineClient` + `DoctorReport`; unit-tested.

## Phase 3 — Static first pass

- [x] **T3.1** Popover shows vault / harness / model from decoded JSON.
- [x] **T3.2** Vault pick-list from `vault.candidates`. → `PickerRow` in the popover;
      switching re-runs the bridge with `SEASTAR_VAULT` pinned, restarting a running
      server so the choice takes effect.
- [x] **T3.3** Model pick-list from the endpoint's reported list (`models`). → same
      `PickerRow`; switching pins `SEASTAR_MODEL`.
- [x] **T3.4** Start/stop toggle wired to the engine; show `server.state` at a glance.
      → `ServerController` spawns/terminates `sea-star serve`; state shown in the pill.
- [x] **T3.5** Apply the Carpet Sea Star palette and glass control surfaces (§7).

## Phase 4 — Graph & polish

- [ ] **T4.1** Re-index codebase-memory (index is stale / shows old `src/seastar/...`).
- [ ] **T4.2** Embed the graph UI (`WKWebView` → `http://localhost:9749`) in a detail window; restyle to palette.
- [x] **T4.3** Menu-bar icon: monochrome template image (`isTemplate = true`), state via form.
      → Solid silhouettes cut from the founder's art, shipped as `Face*MenuBar` asset-catalog
      imagesets (`template-rendering-intent: template`) and named in
      `IconRoster.all[].menuBarAsset`. Detail survives at 18pt because the ink lives in the
      alpha channel and the glyph is template-tinted by the system.
- [ ] **T4.4** Integrate founder-supplied Icon Composer app icon; ship a template fallback.
      → Header cut wired: the detailed art ships as `Face*Header` imagesets and is named in
      `IconRoster.all[].headerAsset` (rendered as a tinted template so the fine line art stays
      legible on the near-black canvas). **Still pending:** the founder's Icon Composer `.icns`
      export (the bundle app icon) — drop it in and it's done.
- [~] **T4.5** Subtle sea-star motif pass (restrained — do not carpet the UI).
      → Header caustic shimmer landed (`Shaders/Caustics.metal` + `Views/CausticsEffect.swift`):
      a slow value-noise highlight that drifts across the header mark only, gated by ink alpha
      (the silhouette never moves — only the light does) and off under Reduce Motion. Broader
      motif pass still to come.
- [ ] **T4.6** Optional per-install "colouration" picker.
- [x] **T4.7** Easter egg — four faces, rerolled on server start/stop. All of the founder's
      icons live in one roster (`Support/IconRoster.swift`); the app wears one at a time and
      rerolls to a **different** face each time the server opens or shuts (never the one that
      just went away). Shown on both the menu-bar glyph and the popover header, each with its
      own glow colour. Now wearing the founder's **real** art (T4.3/T4.4 cuts wired in); the
      header face carries the caustic shimmer (T4.5).

## Phase 5 — Release

- [ ] **T5.1** Local build for the founder (`xcodebuild`), no signing.
- [ ] **T5.2** Later: Developer ID `codesign` → `notarytool submit --wait` → `stapler staple`.
- [ ] **T5.3** Update [PROGRESS.md](file:///Users/lono/Random_MCP/theSeaStar/docs/PROGRESS.md) and append a handoff note.

## Phase 6 — Operator instructions (dual track)

- [ ] **T6.1** Write the **GUI-first** track: zero-terminal install → launch → detect →
      choose → start → stop (§10.1).
- [ ] **T6.2** Write the **terminal-first** track: the CLI equivalent of every GUI action,
      as the §10.2 parity table plus a cheat sheet.
- [ ] **T6.3** Keep the two tracks in sync — same steps, same order, neither second-class;
      verify against the §10.2 parity table at release.
- [ ] **T6.4** Ensure docs state the native, headless Xcode MCP path (§9.1); remove any
      stale "macOS must be shell-first / plugin is iOS-only" claim.
