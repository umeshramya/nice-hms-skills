# Nice HMS skills

Reusable **skills** for AI tools — Claude Code, Codex, Gemini CLI, Cursor, or any agent that
reads `AGENTS.md` — that help a hospital owner or doctor work with their own Nice HMS data.

A *skill* is a short set of instructions the agent loads when the question matches. It tells the
agent which files to read, how to compute the answer, and what the data cannot support. Nothing
here sends data anywhere: the skills run on your machine against files you already hold.

## Two ways to use this repo

**1. With the monthly pack.** The first-of-month email from Nice HMS carries a zip
(`monthly-report-<month>.zip`). Unzip it, open that folder in your AI tool, and ask a question.
The pack already includes its own `AGENTS.md` and `.claude/skills/`, so it works without this
repo. Install these skills only if you want the extra prompts below.

**2. Standalone.** Clone this repo and copy `skills/*` into your project's `.claude/skills/`
(Claude Code) — or simply point any agent that reads `AGENTS.md` at this folder.

See **[INSTALL.md](INSTALL.md)** for the exact command for each tool.

**[PACK-CONTRACT.md](PACK-CONTRACT.md)** is where this repo and the monthly zip meet: the zip
carries the month's data and a short stub, this repo carries everything that is the same for every
client. It describes the target; until the pack changes, packs still ship their own instructions.

## The skills

| Skill | Use it for |
|---|---|
| `financial-status` | The month as a PDF: billed, collected, cash versus digital, debtors, leakage concentration, deposits — with an action ledger carried month to month |
| `doctor-payouts` | Compare what each consultant earned against what was paid, as a labelled what-if |
| `dues-aging` | Split outstanding money between patients and payors, and age it |
| `revenue-leakage` | Rank where billed money was not collected, by amount and cause |
| `research-paper` | Draft a paper from the hospital's own data, with the method and limits stated |
| `presentation` | Turn a figure set into a slide outline an owner can present |

## Guardrails every skill carries

These are properties of honest analysis, not options:

1. **Never invent a number.** If the files do not carry it, say "not in the data".
2. **Names are not keys.** Consultant and department names are free text; the same person appears
   under several spellings.
3. **Say what cannot be answered.** A missing answer is a finding, not a gap to fill.
4. **Percentages need a base.** When the base is zero, give the absolute change and say the
   percentage is undefined.
5. **A what-if is not an order.** Any payout figure is an assumption the doctor supplies, never a
   recommendation to pay.
6. **Nothing leaves the machine unseen.** The skills read local files; the owner decides what is
   shared onward.

## Licence and use

Public, so that any AI tool a hospital already uses can read the instructions — no account, no
API key, nothing to sign. Use it freely with your own Nice HMS packs. It is not a specification of
the data format and it grants no rights to the software that produces the packs.
