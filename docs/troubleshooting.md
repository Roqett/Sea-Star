# Troubleshooting

*Every failure we know about, and the fix. Start with `sea-star doctor` — it tells you
which of the three pieces is unhappy.*

---

## First: run the doctor

```bash
sea-star doctor
```

It checks all three moving parts and names the one that's broken. Most problems are
diagnosed by the line it prints.

| Doctor says | The piece that's broken | Jump to |
| --- | --- | --- |
| `No local inference server answered` | The model | [No runtime answered](#no-runtime-answered) |
| `No vault configured and no Obsidian vault found` | The vault | [No vault found](#no-vault-found) |
| `Vault path is not a directory` | The vault | [Wrong vault path](#wrong-vault-path) |
| Everything, but no `Ready` | Something else | [Read on](#the-host-cant-see-sea-star) |

---

## No runtime answered

**Symptom**

```
Error: No local inference server answered. Start Osaurus (osaurus serve), Ollama,
LM Studio, llama.cpp, vLLM or Unsloth Studio, or set [inference].base_url ...
```

**What it means.** Sea-Star probed the usual local ports and nothing replied. Your model
app is either not running, or listening somewhere Sea-Star didn't look.

**Fix**

1. Start your model app:
   - **Osaurus:** `osaurus serve` (check with `osaurus status` — it should say `running`).
   - **Ollama:** it should already be running after install.
   - **Unsloth Studio / LM Studio:** press the "start server" button in the app.
   - **oMLX:** start the server from the menu bar, or run `omlx serve`.
2. Run `sea-star doctor` again.
3. Still failing? Your runtime is on a non-standard port. Point Sea-Star at it directly in
   `seastar.toml`:

   ```toml
   [inference]
   base_url = "http://127.0.0.1:PORT/v1"
   model = "your-model-name"
   ```

   Or for a one-off: `SEASTAR_BASE_URL=http://127.0.0.1:PORT/v1 sea-star doctor`.

**Quick check.** This should return JSON listing a model. If it doesn't, the problem is the
runtime, not Sea-Star:

```bash
curl http://127.0.0.1:1337/v1/models
```

## No vault found

**Symptom**

```
Error: No vault configured and no Obsidian vault found. Run `sea-star init --vault <path>`
or set [vault] in seastar.toml.
```

**What it means.** Sea-Star couldn't find a folder of notes. This is expected if you don't
use Obsidian (there's no `obsidian.json` to read).

**Fix.** Tell it where your notes are, once:

```bash
sea-star init --vault "~/Documents/MyVault"
```

Any folder of `.md` files works. You do not need Obsidian.

## Wrong vault path

**Symptom**

```
Error: Vault path is not a directory: /Users/you/Documents/MyVault
```

**Fix.** The path is wrong or the folder doesn't exist. Check it and re-run `init`. Watch
for typos in `~` expansion — quote the path.

---

## The host can't see Sea-Star

**Symptom.** You added Sea-Star to Osaurus / Claude Desktop / Cursor / TRAE, but
`ask_seastar` never appears in the tool list.

**Checklist**

1. **Did you fully restart the host?** Most hosts only read MCP config at launch. Quit
   completely (not just close the window) and reopen.
2. **Is the JSON valid?** One stray comma breaks the whole file. If you already had other
   servers, make sure you *merged* into `mcpServers` rather than replacing it. See
   [Connect it](connect.md) for the exact block.
3. **Does `uvx` exist?** The block launches Sea-Star through `uvx`. Test it yourself:

   ```bash
   uvx --from git+https://github.com/Roqett/Sea-Star sea-star version
   ```

   If that errors, install [`uv`](https://docs.astral.sh/uv/). If you'd rather not use
   `uvx`, point the block at a local clone instead:

   ```json
   {
     "mcpServers": {
       "sea-star": {
         "command": "uv",
         "args": ["--directory", "/absolute/path/to/Sea-Star", "run", "sea-star", "serve"]
       }
     }
   }
   ```
4. **Does `sea-star doctor` say Ready?** If Sea-Star itself isn't ready, the host will launch
   it and it will exit. Fix the doctor first.

## An MCP server Sea-Star borrows fails to start

**Symptom**

```
Error: MCP server 'obsidian' failed: ...
```

**What it means.** A server you listed under `[[mcp.servers]]` in `seastar.toml` couldn't
be launched. Sea-Star refuses to pretend the capability exists.

**Fix.** Check the `command` and `args` for that entry — usually a wrong executable name
(`npx` vs `uvx`), a missing package, or a bad vault path in the arguments. Run the command
by hand to see the real error.

---

## Answers are weak, vague, or ask *you* a question

**Symptom.** Sea-Star cites the right note but gives a thin answer, or replies with
something like *"What's the vibe — should I dig deeper?"*

**What it means.** This is almost always **model quality**, not a bug. A small on-device
model (like a zero-download `foundation` model) reasons well enough to *find* the note but
may not *answer* from it cleanly.

**Fix.** Point Sea-Star at a larger model. The plumbing is fine — the model is the ceiling.
Set it in `seastar.toml`:

```toml
[inference]
model = "a-bigger-model"
```

## Citations are loose or missing

**Symptom.** The answer says `Sources: [[Obsidian vault]]` (a folder) instead of a real
note, or there are no citations at all.

**What it means.** Same root cause as above: the model chose a poor wikilink, or forgot to
cite. Sea-Star extracts whatever `[[wikilinks]]` the model wrote.

**Fix.** Use a stronger model, and ask a question that clearly points at one topic. Against
a well-written note, a decent model returns the exact note name.

## First query is slow

**What it means.** On the first call, the model loads into memory. After that it's fast.
This is normal for local inference, not a Sea-Star problem.

---

## Still stuck?

1. Run `sea-star doctor` and read the line it complains about.
2. Re-read [Start here](start-here.md) for the mental model, or [Connect it](connect.md)
   for the wiring steps.
3. Open an issue at **https://github.com/Roqett/Sea-Star/issues** with the doctor output
   and the exact command you ran. Conformance reports ("Sea-Star worked with model X on
   runtime Y") are especially welcome.
