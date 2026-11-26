# Nice HMS skills — instructions for the AI tool

You are helping a hospital owner or doctor read **their own** Nice HMS data. The files are on
this machine. Do not invent figures; every number you state must come from a file you read.

## This file is not the one inside the pack

Two `AGENTS.md` files exist and they are not interchangeable. **This one** travels with the skills
repo and governs everything *around* a run: which folder a pack goes in, the action ledger, the
review, the PDF. **The pack's own `AGENTS.md`** ships inside every monthly zip, is generated for
that month and organisation, and governs the data itself — its guardrails (a balance is not
revenue, a payout cannot be computed, admissions are not discharges, the encounter file is scoped by
voucher, lifetime columns are as of generation, names are not keys) are properties of the files and
this repo does not restate them.

Where they could differ, the pack wins:

- Inside a monthly pack folder — wherever the owner extracted the zip — the pack's `AGENTS.md` and
  `00-START-HERE.md` govern the data. They are generated against the exact files in that folder.
- The skills themselves always come from the installed kit
  (`%USERPROFILE%\Documents\Nice-HMS\kit`), never from the pack. The kit never sits in the same
  directory as a pack, so it never shadows the pack's own instructions.
- When a skill needs a pack rule, it **cites** it, it does not copy it — a copied rule stops
  tracking the pack the day a new pack format ships.
- Every pack this kit supports carries the *balance is not revenue* guardrail. If a pack lacks it,
  the pack is not one this kit can read: stop and say so, rather than papering over the mismatch.

## Rules that always apply

1. **Never invent a number.** If the files do not carry it, say "not in the data".
2. **Names are not keys.** Consultant, department and item names are free text; one person may
   appear under several spellings. Group on an id where one exists, otherwise on a normalised
   name (lowercase, alphanumerics only) — never on the raw string.
3. **Say what cannot be answered.** A missing answer is a finding, not a gap to fill.
4. **Percentages need a base.** If the base month is zero, give the absolute change and say the
   percentage is undefined.
5. **A what-if is not an order.** A share the pack records is used exactly as recorded; any other
   payout figure uses a rate the user supplies. Never present either as what the hospital should
   pay.
6. **Ask before guessing the period.** If the user has not said which month, read `manifest.json`
   (in a monthly pack) or ask.

## The skills

Each lives in `skills/<name>/SKILL.md` with its own instructions. Use the one that matches the
question:

| When the user asks about… | Use |
|---|---|
| the month's money, debtors, cash vs digital, deposits, what to fix | `financial-status` |
| what doctors earned versus what was paid | `doctor-payouts` |
| outstanding money, who owes us, how old it is | `dues-aging` |
| where money is lost, discounts, unbilled work | `revenue-leakage` |
| writing a research paper from hospital data | `research-paper` |
| preparing slides or a talk | `presentation` |

## If a monthly pack is present

A pack contains: `clinical-<from>.csv`, a daily clinical CSV, `store-<orgId>/` and
`financial-<orgId>/` folders, `README.md`, `00-START-HERE.md`, `headline.json`, `quality.json`
and `manifest.json`.

Read `manifest.json` first — it lists the period, the organisations, every file and what is
missing. Read `quality.json` before drawing conclusions: it states which figures the pack does
not support.

Unzip each month into its own folder, wherever the owner keeps their packs (for example
`Downloads\monthly-report-2024-12-01\`); keep months as siblings so one month never lands on top of
another. **The extracted pack folder is the project folder** — the unit of work and of backup.
Every zip carries the same inner filenames, so unpacking a new month into an older month's folder
overwrites it silently. Confirm the period from `manifest.json`, not from the folder name.
Deliverables (the PDF, the payout workbooks, the mail list) go in that project's `out\` folder, not
beside the pack CSVs and not in any central folder.

## If no pack is present

Ask the user for the files, or for the path to their unpacked pack. Do not proceed on assumed
data.

## The action ledger

`financial-status` keeps a memory that outlives any one pack, because each monthly zip is new:

```
<project>\                     the extracted monthly pack — the unit of work and of backup
  <pack CSVs, manifest.json, quality.json, financial-<orgId>\, store-<orgId>\>
  out\                         this month's deliverables — PDF, payout workbooks, mail list
  reviews\                     actions-<YYYY-MM>.csv for this month
  actions.json                 the ledger — copied forward into every new month, never reset
  recipients.json              who to address — role,name,email,cc[,share_pct], supplied by the hospital
  actions-reminders.ics        reminders for the open actions
```

Everything a month needs is inside that project folder, so it can be backed up and copied to
another computer whole. The kit is installed once per computer and is not carried in the project
folder.

- **Read it before writing anything.** Score every `open` action against this month's files and ask
  the owner about each: done, accepted, disputed, dropped.
- **Never overwrite it.** Add this month's actions, update statuses, keep the history.
- `accepted` means the owner has chosen to live with it — **stop raising it**. `disputed` means the
  AI was wrong — record it and do not raise it again.
- The ledger holds no patient data beyond the debtor call list.

## Who the output is for

Everything a run produces — the PDF and the per-consultant workbooks — is addressed to the
hospital's **admin / person-in-charge**, never to a doctor directly. `recipients.json` gives the
roles (`admin`, `finance`, `store`, `pharmacy`, `doctor`) and their addresses so the admin can
forward a doctor's own workbook if they choose. **The skill emails no one.** Fill each recipient
from what that hospital actually records; where pharmacy or store is not recorded, that recipient
gets a one-line statement, never a zero. Match a consultant to an email by **exact name only** —
report an unmatched name, never guess.

## Sending a question back

If a question cannot be answered from the data, tell the user plainly and suggest they raise it
with Nice HMS — do not improvise an answer.
