# The cockpit, reassessed — it is Frankenstein, and here is the wiring

Written 2026-10-02, replacing an earlier and too-generous version of this report. The
founder's correction: *"it is Frankenstein because … that 'what each app is doing' and
'what's idle' and 'new on this machine', all that shit is meant to be just part of an
onboarding window, not part of the standard mechanics of the app."* He is right. This
version says so.

## What the app actually has, in full

Two surfaces. That is all.

| surface | job as written | what is in it |
| --- | --- | --- |
| **The popover** (the star in the menu bar) | A reading, open for a moment | Header (icon, title, status pill, **mode switch**, depth/layout switch, gear) · graph **or** list · logs · Start |
| **Settings window** | The knobs | Engine · Vault · Harness · Logs · Updates · Links |

**There is no onboarding surface.** Not a window, not a sheet, not a step. Everything that
the register, the ledger and the idle list are for has had nowhere to live except the
cockpit, and that is precisely how it ended up in there.

## What the popover was, and what it is now

Before this session, the list reading was two things: the four rows, and the idle list.

```
details = four rows  +  idle list
```

After this session it is four:

```
details = four rows  +  ledger  +  idle list  +  register
```

I added two of those four, today, one after the other, each time asking "where does this
go?" and each time answering "append it to the panel". That is the whole of it. Not drift
over months — three additions in one day, mine, with no decision about whether the popover
was the right surface for any of them. It was not.

## Why the graph became unreachable — the symptom that matters most

The mode switch lives in the **header**, which is at the **top** of the popover. The
popover has a width cap (`frame(width: panelWidth)`) and **no height cap**. The height cap
that exists (`maxPopoverHeight`) was applied only to the graph's pool, never to list mode —
list mode is written to "hug its own content".

So list mode grew past the height of the display. When a popover does not fit, macOS keeps
it on screen by moving it **up**. The bottom stays put; the top goes above the top edge of
the screen.

Look at the screenshot again with that in mind: the very top shows *"on device."* — the
header's **subtitle**, with the title and every control beside it cut off — and the bottom
shows Logs and Start, intact. The top is cut, the bottom is whole. That is the signature.

**The graph was one click away the entire time. The click was off-screen.** Nothing was
broken; the control you needed had been pushed above the top of your display by three
sections nobody had decided to put there.

## The three things that were welded in, and where each belongs

**1. "New on this machine" — the register.** Eleven questions, each with an evidence line,
an editable name and two buttons. This is the tallest thing in the panel and the least
urgent.

*It is onboarding.* It happens once, it is about setting the app up, and afterwards it is
mostly silent. It has no business in a panel that opens for a moment to tell you how things
are going.

**2. "What each app is doing" — the ledger.** Genuinely valuable, and genuinely not a
reading you need every time you open the cockpit. It answers "is anything on this machine
doing something I should know about?", which is a question you ask deliberately, not one
that should occupy the panel you glance at.

*It belongs with onboarding* — "here is what is on your machine" is exactly what a first
run should say — and afterwards behind a deliberate door.

**3. The idle list with float/take-off buttons.** These are **graph visibility controls**.
The buttons say "Float on the graph" and "Take off the graph". They control the graph, they
are about the graph, and they are sitting in the *list* reading, which is the one place they
can have no effect on what you are looking at.

*They belong in graph mode*, next to the thing they change.

## What is wrong with the four rows themselves

Two smaller faults, both in the same family — a line saying something other than the fact
it sits next to:

- **Vault** shows the literal word *"Notes"* as its detail line. That is a label used as a
  value; the count never appears.
- **Harness** shows *"Installed, not running"* while its own value reads *"None attached"*.
  That is some other app's rung, shown where the fact is that nothing is attached at all.

## What is *not* wrong

The engine, the register, the ledger and the graph are all correct in what they report.
DeepSeek Harness really is reaching two hosts. oMLX really is serving on 8009 and using it.
The graph renderer, reached directly, still draws. **What failed is the choice of surface,
and only that.**

## The fix: one job per surface

Three surfaces, and each of them gets to be good at one thing:

### 1. The cockpit — the everyday reading, and nothing else

- **Header, always visible, never scrolled away:** mode switch (graph / list), the
  contextual depth or layout switch, status pill, gear.
- **Graph mode:** the graph, plus its own controls — the float/take-off list — beside it,
  because they change what you are looking at.
- **List mode:** the four rows and the working-now band. Nothing else.
- **A hard height ceiling on the whole popover**, with exactly one scroll region inside it
  if the content ever exceeds it. This is the change that makes the current failure
  *impossible* rather than merely repaired.

### 2. Onboarding — its own window, and the home for all of this

- "Here is what is on your machine" — the ledger.
- "Eleven things to decide about" — the register, with its evidence.
- "Which of these should show on your graph" — the float/take-off choices, offered once so
  the graph starts out meaning something.
- Opens on first run. Reachable afterwards from the menu bar and from Settings
  ("Set up Sea-Star…"). Never inside the popover.

### 3. Settings — the knobs, as they are today

Unchanged, except that it gains a door to onboarding.

## Why this is a decision, not a repair

Two of the three moves change what the app *is*: the register leaving the cockpit, and a
new window existing at all. Those need the founder's agreement before anyone restructures
the views. The mechanical half — the height ceiling, the two wrong detail lines — is a
repair and can follow immediately.

## What I would do in what order

1. **The height ceiling and one scroll region.** Small, and it ends the "controls pushed off
   the screen" class of failure for good.
2. **Empty the list reading back down to the four rows**, moving the ledger and register
   into the new onboarding window.
3. **Move the float/take-off list into graph mode**, where it does something.
4. **Fix the two detail lines**, and give the register a proper first-run moment in the
   window rather than a folded section at the bottom of a reading.

Steps 1 and 4 are Flash work. Steps 2 and 3 are a substantial restructure of the view
layer and the introduction of a second window — work for the Pro model, with this document
as the brief.
