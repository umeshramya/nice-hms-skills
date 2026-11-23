# What the monthly pack must contain

**Target state.** Packs sent before this contract still carry `README.md`, `00-START-HERE.md`,
their own `.claude/skills/` and `tools/`. Newer packs carry data and the stub only — if you have
an older pack, nothing breaks; the duplicate instructions it carries are simply no longer
maintained.

## The rule

The zip carries **only what exists at send time, for that hospital, that month**. Test every file:
*would this line differ for another hospital, or another month?* If no, it belongs in the repo.

The point is not size — the files being removed total ~63 KB against 1.8 MB of CSV. It is that
there is **one file to fix**, and a fix reaches every client the same day instead of next month.

| File | Keep | Why |
|---|---|---|
| `clinical-<from>.csv`, `clinical-daily-<from>.csv` | yes | the month |
| `financial-<orgId>/*.csv`, `store-<orgId>/*.csv` | yes | the month |
| `manifest.json` | yes | period, organisations, files, what is missing |
| `quality.json` | yes | what *this* pack cannot support — not knowable in advance |
| `headline.json` | yes | the vendor's own figure, to cross-check against |
| `AGENTS.md` | yes, the stub below | safety net before anything is installed |
| `CLAUDE.md`, `GEMINI.md` | yes, `@AGENTS.md` | so the stub loads on its own |
| `README.md` | **no** | per-column prose for every pack; the repo owns it |
| `00-START-HERE.md` | **no** | routing table, identical for every client |
| `.claude/skills/*/SKILL.md` | **no** | this is the copy that conflicts — two skill sets fire on one question |
| `tools/*.py`, `payout-rates.csv` | **no** | repo; and it would need Python on a hospital PC |

## The stub `AGENTS.md`

Generated per pack, ~15 lines, carrying the period, the organisation and the kit version:

```markdown
# <org> — monthly pack, <period>

This folder is data. What to do with it lives in the Nice HMS kit.

## Step 0 — is the kit installed?

If %USERPROFILE%\Documents\Nice-HMS\kit is missing, or its skills.json version is lower than
`kit: <version>`, stop and install it from <url>, then reopen this folder.

## Until the kit is installed

A balance column is a position at that moment, not money earned or collected this month.
Never add cash_inr, digital_inr and bank_inr together and call the result revenue.
Revenue and collections come from financial-summary.csv.

## About this pack

manifest.json gives the period and the files. quality.json says what this pack cannot
support. Both are about this month and override anything general.

## A question this pack cannot answer

Send it back with its provenance — <the generated feedback curl>.
```

## Version handshake

Two numbers, deliberately different:

- **`kit:` in the pack** is a *floor* — the oldest kit that pack was generated against. Fixed at
  send time; a pack may be opened years later with a much newer kit, and that is fine.
- **the commit on `main`** is the *ceiling* — the newest kit available right now. This is what
  changes when a skill is fixed.

The pack's `kit:` value matches `version` in `skills.json` (currently `0.2.0`). Checks, in order:

1. **No kit, or kit version below `kit:`** → say so, install, and until then only the lines under
   *Until the kit is installed* apply. Never run a pack on a kit older than it asks for.
2. **Kit present and at or above `kit:`** → run. Then, separately, check for a newer kit.

### How the "is there a newer kit" check works — no git required

`skills.json` in the kit carries three URLs: `repo`, `check`, `zip`. The check is one HTTPS GET:

```
GET https://api.github.com/repos/umeshramya/nice-hms-skills/commits/main
→ { "sha": "<40 hex>" , ... }
```

The installer writes the `sha` it installed at into `installed.json` beside `skills.json`:

```json
{ "version": "0.2.0", "commit": "<40 hex>", "installed": "2026-11-23" }
```

When the two `sha` values differ, a newer kit exists. Tell the owner, show the `zip` URL, and on
their say-so download it and replace the kit folder. Updates are **whole-folder replacements**, not
merges — the kit is not the owner's to edit, and a local edit is a lost edit.

Run this check **twice**: when a pack folder is opened (the stub's Step 0) and when a new pack's
email arrives. Both are moments the doctor is already looking at the kit.

**Not chosen:** `git pull` (needs git on a hospital PC), npm (needs Node *and* a registry publish
per fix). Both add a dependency to solve a problem a plain HTTPS GET already solves.

## What the kit must carry instead

Installed once, in one place, fixed for every client at the same time:

- the six `SKILL.md` files;
- `xlsx` — a stdlib-only multi-sheet writer, because a payout is a workbook and no hospital PC
  should need a package installed to get one (PowerShell on Windows, which is always present);
- the ledger template and the `.ics` pattern the skill documents.

## The email body

Read before the zip is even opened, so it carries the install line:

> First time: install the Nice HMS kit from <url> once. After that, the pack and every later
> month open ready to use.

## What the pack generator must do

1. Put `manifest.json`, `quality.json`, `headline.json` and every CSV in the zip.
2. Put nothing else in except the stub `AGENTS.md` and the two one-line shims.
3. Carry `kit: <version>` in both the stub and `manifest.json`.
4. Carry the provenance-stamped feedback curl in the stub, so a question can come
   back even when the pack is opened by a tool that reads no other file.
5. Keep the README and the per-question prompts in this repo, not in the zip.
