# Shipping Sea-Star

Everything needed to put Sea-Star on someone else's Mac, and an honest account of
what is still missing. Written so a person who does not enjoy the terminal can
work through it once and not think about it again.

## The one thing a Mac cannot do for itself

Apple will notarise software for an anonymous author. That is the whole of the
gate, and it needs three things that only you can provide:

1. **A paid Apple Developer Program membership** — developer.apple.com, about
   US$99 a year. There is no free path to a notarised Mac app.
2. **A Developer ID Application certificate.** Xcode → Settings → Accounts →
   your Apple ID → Manage Certificates → `+` → *Developer ID Application*. It
   lands in your login keychain.
3. **A Team ID**, the ten-character code on the Membership page, and an
   **app-specific password** from appleid.apple.com for the upload.

Store the upload credential once:

```bash
xcrun notarytool store-credentials seastar-notary \
  --apple-id you@example.com \
  --team-id YOUR_TEAM_ID \
  --password <app-specific-password>
```

Then, from the repository root:

```bash
export SEASTAR_TEAM_ID=YOUR_TEAM_ID
./script/release.sh
```

Without any of that, this still works and is useful:

```bash
./script/release.sh --dry-run
```

It builds, packages and labels the result honestly. The DMG it produces is
ad-hoc signed and **will be refused by Gatekeeper on any other Mac** — which is
the correct behaviour, not a bug. The dry run exists so the pipeline can be
proven before the account exists.

## What the script does, and why in that order

Each step stops the whole thing rather than continuing with something broken:

1. **Checks for the certificate, the Team ID and the notary credential first.**
   These are the likely failures, and finding out after a twenty-minute build is
   a waste of your afternoon.
2. **Builds Release with the hardened runtime.** Notarisation requires it, and a
   hardened runtime is meaningless without a real signature — so the Release
   configuration deliberately *fails to build* without a Developer ID rather than
   falling back to ad-hoc. A build error is a better teacher than a support
   message from a stranger whose Gatekeeper refused the download.
3. **Verifies the signature** and checks the hardened runtime is actually on.
4. **Packages a DMG** with a symlink to `/Applications`, so installing is the
   drag most Mac users already know.
5. **Signs the DMG itself**, because Gatekeeper assesses the thing that was
   downloaded, not only what is inside it.
6. **Submits to Apple and waits**, then **staples** the ticket so the app opens
   without an internet connection.
7. **Asks Gatekeeper for its own verdict** with `spctl`. Everything above can
   report success while Gatekeeper still refuses; this step is the only one that
   checks the answer that matters.

## Two routes to people, and why one of them is not open yet

**Developer ID + notarised DMG — the route this script builds.** The app is
downloaded from GitHub, dragged to Applications, and opens. The app can spawn
the Python engine, read the vault wherever it lives, and run unsandboxed. This
fits how Sea-Star actually works.

**Mac App Store — not available to this design, and probably never.** App Store
apps must be sandboxed. Sea-Star reads an Obsidian vault from an arbitrary
folder and spawns a Python engine as a child process; both are exactly what the
sandbox exists to prevent. Sandboxing it is not a signing task, it is a rewrite
of how the app reaches your notes. Worth deciding deliberately rather than
discovering halfway through a submission.

## The remaining gap, stated plainly

**The engine is not inside the bundle.** The DMG contains the menu-bar app and
nothing else. On this machine that is invisible, because the app finds the
repository and the `sea-star` command on `PATH`. On a stranger's Mac it finds
nothing, and the app has no engine behind it.

That gap is why a notarised DMG is *not yet worth distributing*, and no amount
of signing fixes it. Closing it means, in rough order of effort:

1. **Vendor the engine into `Contents/Resources/engine`** and point
   `EngineCommand.resolve()` at the bundle before it looks at `PATH`. This is
   the smallest honest step, and it still assumes the person has `uv` or a
   Python 3.11+.
2. **Bundle a relocatable Python** (python-build-standalone) alongside the
   engine, so the app is genuinely self-contained. Heavier, and the point at
   which the DMG becomes something a non-technical person can use.

The release script says this out loud on every run rather than letting it surface
after notarisation, when the DMG looks finished and is not.

## Version numbers

`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` live in `macapp/project.yml`
and are the only places either is written. The script reads them and names the
DMG `Sea-Star-<version>.dmg`. Bump the build number for every upload: Apple
rejects a repeat of a version it has already seen, and the rejection arrives
minutes later rather than immediately.

## What a release needs before anyone downloads it

- [ ] The engine bundled, per the section above.
- [ ] `./script/release.sh` completes and ends with the Gatekeeper verdict.
- [ ] An app icon at every size. There is artwork in `assets/`, and `LSUIElement`
      is on, so the app lives in the menu bar rather than the Dock.
- [ ] The README's requirements match reality — today it promises a macOS app and
      does not say it needs a local model server running.
- [ ] A note that it is early, in the founder's own words rather than an
      engineer's.
