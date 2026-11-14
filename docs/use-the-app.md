# Use the App

*Two ways to drive Sea-Star — click it, or type it. Both do the same things, in the same
order. Neither is the "advanced" one.*

---

## Which door are you?

- **You'd rather not touch a terminal.** Read the **Cockpit** half below. Zero typing.
- **You live in a terminal.** Read the **Terminal** half. Same engine, same steps, typed.

The rest of this page keeps the two views side by side so they never drift apart.

---

# The Cockpit — zero terminal (the default)

Sea-Star ships as a small **menu-bar app** called the Cockpit. There is no window to manage
and nothing to type: it sits in the top-right of your screen and you click it.

> A **menu-bar app** has no icon in the Dock and no window of its own until you click it. If
> you're looking for Sea-Star "in your apps", look at the top-right of the screen instead —
> that's the star.

## 1. Get it onto your Mac

For now Sea-Star is **version 0.1.0 and a local build** — it is built on the machine it runs
on, not yet a signed download. (A notarised, double-click download for other people comes
later.) Once built, launch it and a small **star** appears in the menu bar.

## 2. Open the Cockpit

**Left-click** the star. A compact panel drops down — that's the Cockpit.

## 3. Read what Sea-Star found

The top of the panel is a single word: **Ready** (all good) or a plain-language note about
what's missing. Below it are three rows:

| Row | What it is |
| --- | --- |
| **Vault** | The folder of notes Sea-Star is using. |
| **Harness** | The app that answered with a model — your *model runner* (Osaurus, Ollama, LM Studio, oMLX…). |
| **Model** | The specific model that runner is offering. |

You did not type any of this. Sea-Star found the folder and the runner by itself.

## 4. Choose, if you want to

Each row is a small menu:

- **Vault** — pick another known vault, or choose **Open folder…** to point at any folder at
  all. The one in use is ticked.
- **Harness** — appears as a pick-list only when more than one is running. Pick the one you
  want Sea-Star to use.
- **Model** — always follows the chosen harness, so it lists that runner's own models. Pick
  the one you want.

Change any of these and Sea-Star re-reads the setup; if the server is running it restarts so
the change takes effect.

## 5. Go

- **Start** (bottom-left) turns the Sea-Star server on.
- **Refresh** (bottom-right) re-scans for the vault, runners and models.
- The **Ready** word tells you the state at a glance; you never have to read a log to know
  if it's up.

That is the whole everyday loop: **detect → choose → start → stop**, all by clicking.

## The rest of the Cockpit

- **Logs** — a row you can expand to see the engine's own output in plain monospace. It's
  kept deliberately short and cleans itself up (see Settings below).
- **Graph | List** — the header's two small symbols flip between two readings of the same
  facts: **List** is the plain rows; **Graph** draws your vault, runners and models as
  glowing nodes, with the live connection drawn between them. Pick one the first time and
  it remembers.
- **The starfish note** — occasionally a short line grows from the starfish to tell you
  something useful ("this runner is new to us", or "you may be pointed at the wrong vault").
  Tap the starfish to expand or dismiss it.
- **Right-click the star** for the standard app menu: **Check for Updates…**, **Settings…**
  (⌘,), **Help & Comments**, **Patchdog**, the version, and **Quit Sea-Star** (⌘Q).
- **Settings…** opens a proper window for the quieter jobs: the vault list with a search box,
  the harness and model pickers, a manual update check, and links — plus a **Logs** section
  where you choose how long logs are kept (the default is 14 days) and can **Clear now**.

## If something is missing

If there is no vault or no runner answering, the Cockpit says so **in plain language** and
points at the fix. It never drops you into a terminal.

---

# The Terminal — full parity (for people who live there)

The same engine, driven directly. Every Cockpit action has an exact command, so nothing is
ever *only* possible by clicking.

| Cockpit action | Terminal equivalent |
| --- | --- |
| Read what was found (vault / runner / model) | `uv run sea-star doctor` |
| Same, machine-readable | `uv run sea-star doctor --json` |
| Choose the vault (point at a folder) | `SEASTAR_VAULT=/path uv run sea-star doctor` |
| Choose the runner | `SEASTAR_BASE_URL=http://127.0.0.1:8009/v1 SEASTAR_RUNTIME=omlx uv run sea-star doctor` |
| Choose the model | `SEASTAR_MODEL=<name> uv run sea-star doctor` |
| Go — start the server | `uv run sea-star serve` |
| Stop the server | `Ctrl-C` |
| Create the settings file | `uv run sea-star init` |
| Ask the vault a question | `uv run sea-star ask "…"` |
| Scan extra ports for a runner | `SEASTAR_SCAN_PORTS=8009,5000 uv run sea-star doctor` |
| Keep the engine green | `uv run ruff check . && uv run pytest` |

### Cheat sheet

```bash
uv run sea-star doctor            # read the setup (human-readable)
uv run sea-star doctor --json     # the same, machine-readable
uv run sea-star serve             # start the MCP server (Ctrl-C to stop)
uv run sea-star init              # write seastar.toml once
uv run sea-star ask "…"           # ask your own notes, get citations
uv run ruff check . && uv run pytest   # keep the engine green
```

### Building the Cockpit from source

If you'd rather build the app than run the engine, the app lives in `macapp/` and builds with
XcodeGen + `xcodebuild`:

```bash
cd macapp
xcodegen generate
xcodebuild -project SeaStar.xcodeproj -scheme SeaStar -config Debug build
open build/Build/Products/Debug/Sea-Star.app
```

On a fresh machine, Xcode's Metal toolchain must be present for the header shimmer to
compile: `xcodebuild -downloadComponent MetalToolchain`.

> **On automation:** macOS builds do **not** have to be shell-first. Xcode 27 ships its own
> headless MCP surface (`xcrun mcp-server` + `xcrun mcpbridge`) — the tool service runs even
> with Xcode.app closed; it only needs a workspace open and a client that holds the pipe
> open. The third-party `xcodebuildmcp` package is for iOS/Simulator work and is not required
> here.

---

## Keeping the two tracks in step

The two halves above are one product seen from two sides. **A change to one is a change to
the other**, and the parity table is the contract: same steps, same order. If a Cockpit
action ever lacks a command (or the reverse), that is a bug — say so, and we fix whichever
side is behind.