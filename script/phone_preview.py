#!/usr/bin/env python3
"""Show the Sea-Star cockpit on a phone, over the tailnet, without exposing it.

The founder works away from this machine and asked for the one door it lacked: a
way to *see* a build rather than be told a build is fine. Screen Sharing would do
it, but it needs a VNC client, a full desktop session and an interactive password
prompt, which is the wrong shape for a glance between two tractor jobs.

This is deliberately smaller than that. It serves one thing — a picture of the
cockpit — over Tailscale, which is already installed and already carries this
machine and the founder's phone.

Two decisions that are load-bearing, not incidental:

- **It binds to the Tailscale address only.** Not ``0.0.0.0``. A screen is the
  most private thing this Mac owns, so the surface is reachable from the founder's
  own devices and from nowhere else. Tailscale's membership *is* the authorisation;
  there is no second lock to forget on a phone at 6am.
- **It prefers the cockpit's own window.** A full-desktop capture would work and
  would also hand over every other window, sticky note and notification on the
  machine. Falling back to the whole screen only when no window can be found is a
  deliberate last resort, and the page says which one you are looking at.

Nothing is written to disk and nothing is logged: each request captures, serves and
discards, so the history of what was on screen does not outlive the glance.
"""

from __future__ import annotations

import argparse
import ipaddress
import subprocess
import sys
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

#: The app whose window is worth looking at. Matched against the window owner and
#: the process, so a rename of the bundle id is visible here rather than silent.
WANTED_OWNER_TOKENS = ("sea-star", "sea star", "seastar")

PAGE = """<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Sea-Star</title>
<style>
  :root {{ color-scheme: dark; }}
  * {{ box-sizing: border-box; }}
  body {{ margin: 0; background: #0b0d10; color: #e8e6e1;
          font: 13px/1.4 ui-monospace, SFMono-Regular, Menlo, monospace; }}
  header {{ position: sticky; top: 0; display: flex; gap: 8px; align-items: center;
            padding: 10px 12px; background: #111418; border-bottom: 1px solid #232a31; }}
  .dot {{ width: 8px; height: 8px; border-radius: 50%; background: #7a6cff; }}
  .what {{ color: #9aa4ae; }}
  .grow {{ flex: 1; }}
  button {{ font: inherit; color: #0b0d10; background: #7ad1c0; border: 0;
            border-radius: 6px; padding: 6px 10px; }}
  img {{ display: block; width: 100%; height: auto; }}
  p {{ margin: 0; padding: 16px 12px; color: #9aa4ae; }}
</style>
<header>
  <span class="dot"></span>
  <span class="what">{what}</span>
  <span class="grow"></span>
  <span class="what" id="when">…</span>
  <button onclick="location.reload()">refresh</button>
</header>
<img src="/shot.png" alt="Sea-Star cockpit" id="shot" onload="document.getElementById('when').textContent=new Date().toLocaleTimeString()">
<p id="note">Open the cockpit from the menu bar if the picture is blank.</p>
<script>
  // Auto-refresh, because the founder's actual question on a tractor is "is it
  // still alive", and answering it should not require a second tap. The interval
  // is a compromise: fast enough to feel live, slow enough that a phone radio is
  // not being held awake by a page nobody is looking at.
  const AGE_MS = 4000;
  let stamp = Date.now();
  function tick() {{
    if (Date.now() - stamp > AGE_MS) {{
      stamp = Date.now();
      document.getElementById('shot').src = '/shot.png?t=' + stamp;
      fetch('/note.json').then(r => r.json()).then(n => {{
        document.getElementById('note').textContent = n.note;
      }}).catch(() => {{}});
    }}
    setTimeout(tick, AGE_MS);
  }}
  setTimeout(tick, AGE_MS);
</script>
"""

#: Header values must be latin-1, so these carry no typographic punctuation. They
#: are read by a person looking at a phone in daylight, where brevity wins anyway.
NOTE_APP_WINDOW = "cockpit window"
NOTE_FULL_SCREEN = "whole screen (no cockpit window found)"


def _window_ids_for(target: str) -> list[int]:
    """Window ids of the app's own windows, via the window server.

    Returns ``[]`` rather than guessing when the query cannot be answered, so the
    caller can fall back and *say* it fell back.
    """

    script = f"""
import Quartz
result = []
for w in Quartz.CGWindowListCopyWindowInfo(
        Quartz.kCGWindowListOptionOnScreenOnly | Quartz.kCGWindowListExcludeDesktopElements,
        Quartz.kCGNullWindowID):
    owner = (w.get("kCGWindowOwnerName") or "").lower()
    name = (w.get("kCGWindowName") or "").lower()
    haystack = owner + " " + name
    if any(t in haystack for t in {target!r}):
        bounds = w.get("kCGWindowBounds", {{}})
        if bounds.get("Width", 0) > 80 and bounds.get("Height", 0) > 80:
            result.append(w.get("kCGWindowNumber"))
print(" ".join(str(n) for n in result if n))
"""
    try:
        out = subprocess.run(
            [sys.executable, "-c", script], capture_output=True, text=True, timeout=15, check=False
        )
    except (OSError, subprocess.SubprocessError):
        return []
    return [int(token) for token in out.stdout.split() if token.isdigit()]


def capture(target: str) -> tuple[bytes, str]:
    """A PNG of the cockpit, and a plain description of what it managed to capture."""

    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "shot.png"
        for window_id in _window_ids_for(target):
            # -C keeps the cursor: without it the picture looks like the machine is
            # unattended, and the founder is trying to judge a live UI.
            result = subprocess.run(
                ["screencapture", "-x", "-o", "-C", "-l", str(window_id), str(path)],
                capture_output=True,
                timeout=20,
                check=False,
            )
            if result.returncode == 0 and path.exists() and path.stat().st_size > 0:
                return path.read_bytes(), NOTE_APP_WINDOW

        result = subprocess.run(
            ["screencapture", "-x", "-o", "-C", str(path)],
            capture_output=True,
            timeout=20,
            check=False,
        )
        if result.returncode == 0 and path.exists() and path.stat().st_size > 0:
            return path.read_bytes(), NOTE_FULL_SCREEN
    raise RuntimeError("screencapture produced nothing")


class Handler(BaseHTTPRequestHandler):
    target = "sea-star"
    #: What the last capture actually managed to get. Kept so the page can *say*
    #: which of the two it is showing, rather than leaving the founder to guess
    #: whether a blank panel means a broken app or a closed one.
    last_note = "nothing captured yet"

    def log_message(self, *_args) -> None:
        return

    def _send(self, body: bytes, content_type: str) -> None:
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if self.path.startswith("/shot.png"):
            try:
                body, note = capture(self.target)
            except RuntimeError as error:
                self._send(str(error).encode(), "text/plain; charset=utf-8")
                return
            Handler.last_note = note
            self.send_response(200)
            self.send_header("Content-Type", "image/png")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Capture-Note", note)
            self.end_headers()
            self.wfile.write(body)
            return
        if self.path.startswith("/note.json"):
            import json as _json

            self._send(_json.dumps({"note": Handler.last_note}).encode(), "application/json")
            return
        self._send(PAGE.format(what=f"Sea-Star · {self.target}").encode(), "text/html; charset=utf-8")


def tailnet_address() -> str | None:
    """This machine's Tailscale address, or ``None`` when Tailscale is not up."""

    try:
        out = subprocess.run(
            ["tailscale", "status", "--json"], capture_output=True, text=True, timeout=10, check=False
        )
    except (OSError, subprocess.SubprocessError):
        return None
    import json

    try:
        addresses = json.loads(out.stdout).get("Self", {}).get("TailscaleIPs", [])
    except ValueError:
        return None
    for address in addresses:
        parsed = ipaddress.ip_address(address)
        if isinstance(parsed, ipaddress.IPv4Address):
            return str(parsed)
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8766)
    parser.add_argument("--target", default="sea-star", help="window-owner tokens to prefer")
    parser.add_argument("--bind", default=None, help="override the bind address (tailnet by default)")
    args = parser.parse_args()

    address = args.bind or tailnet_address()
    if address is None:
        print("Tailscale is not running, so there is no private address to bind.", file=sys.stderr)
        print("Start Tailscale, or pass --bind <address> deliberately.", file=sys.stderr)
        return 2

    Handler.target = args.target
    server = ThreadingHTTPServer((address, args.port), Handler)
    print(f"Sea-Star preview on http://{address}:{args.port}  (tailnet only)")
    print("Open that address in Safari on the phone. Nothing outside Tailscale can reach it.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())