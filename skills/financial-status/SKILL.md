---
name: financial-status
description: Use when the owner asks for the month's financial status — billed, collected, outstanding, cash versus digital, whether the money reached the bank — delivered as a PDF, with a running action ledger carried month to month.
---

# Monthly financial status

Give the owner the month in one PDF they can read, sign, and act on — and be honest about the
edges.

## Read first

1. The pack's **own `AGENTS.md`** — it ships inside the zip and is generated for that month and
   organisation. Its guardrails are properties of the data and this skill does not restate or
   override them. If it is absent, or lacks the *balance is not revenue* guardrail, the pack is
   older than this skill assumes: say so and do not proceed on assumptions.
2. `manifest.json` — the period, the organisations, every file, and what is missing.
3. `headline.json` — the headline figures already computed for this month.
4. `quality.json` — `notSupported` and `notChecked`. Read this **before** you write conclusions.
5. `financial-<orgId>/financial-summary.csv` — one row: billed, credit notes, receipts, refunds,
   collected, outstanding, receivables by patient and payor, payables, and the **cash / digital /
   bank balances** at month end.

## Then

- `day-book.csv` — one row per voucher. For **receipts**, the collection split is
  `dr_type` (CASH / BANK / the hospital's own digital account types) and the free-text `mode`
  column. **Group on `dr_type`, never on `mode`.** If `mode` carries more than a handful of
  distinct values it is not a controlled payment-type field; say so rather than report a split
  built from it.
- `day-summary.csv` — collected per day, useful for the trend line.
- `debitors.csv` — patients who owe money: `account_id`, `name`, `mobile`,
  `opening_balance_inr`, `debits_inr`, `credits_inr`, `balance_inr`.
- `insurance-due.csv`, `aging.csv` — payor dues, and how old the money is.
- `leakage.csv` — money billed and not collected, one row per line, carrying `party`, `uhid`,
  `account_type`, `category`, `sub_head`, `item`, `notes` and `biller`.

## Debtors belong in the summary

Not buried in an appendix. In the summary section show:

1. **How many patients owe, and how much** — the count and the total balance.
2. **The top ten by balance**, with mobile, so the owner can act on them this week.
3. **Concentration** — the share of total patient dues carried by the top five. If the top five
   carry most of it, say so in one line; the rest of the list is a long tail and is not worth
   the owner's morning.
4. **The old money** — how much of the total sits in the 90+ bucket, and how many accounts.

## Who or what is driving the leakage

The leakage total alone changes nothing. Find the concentration, and name it — but name it as
**a question to ask**, never as a finding of fault.

Look in this order, and stop when one explains most of it:

1. **The party** — group `leakage.csv` on `party` / `uhid`. If one payor or one patient accounts
   for a large share, say the name and the amount.
2. **The category** — group on `category` and `sub_head`. One service line discounted hard is a
   pricing decision; the same line across many billers is a tariff problem.
3. **The biller** — group on `biller`. This is *who recorded it*, which is who to ask. Phrase it
   exactly that way: "₹X of discounts were last updated by <name> — ask them what the reason was."
   Never call a biller dishonest, and never imply a discount is theft: a discount the owner granted
   is a decision, not an error.
4. **The cross-check with debtors** — a patient with a large balance who also appears in leakage
   rows is the first call to make. Match `leakage.uhid` to `debitors.account_id`; if those differ
   for an organisation, match on exact name instead and say the match is by name.

Only claim concentration when it is real — the top few explaining a clear majority. Do not rank
the long tail and do not present a 2% share as "the cause". The **revenue-leakage** skill owns the
full ranked cause list; this PDF carries only the concentration and the point to it.

## Integrity signals — ask the owner first, then look

This section looks for patterns that *can* indicate manipulation. It exists because the owner may
suspect a user or a consultant, and the pack either supports that suspicion, or does not.

**It never alleges.** A pattern is a question with numbers behind it, addressed to the owner.

> **These are AI-generated suspicions and may be wrong.** The data knows what was recorded, not why.
> **Ask the administrator what they know from the floor** — who was on leave, which rate was
> approved, whose relative was treated — before acting on any of it. This sentence goes on the page
> in **bold**, above the questions, every time.

### Step 0 — always, before any number is written

Ask the owner, in conversation, and record the answers:

1. Who had billing access this month? Has anyone resigned, been warned, or left recently?
2. Is there any user you already distrust, or have you had to correct one?
3. Is there a consultant you are already in dispute with over share or volume?

Then apply the answers:

- A person the owner **vouches for** may still be shown — but marked **"vouched by the owner"** and
  stated as an explanation, not a question.
- If the owner **will not answer**, report the signals **without names** — counts, amounts, and the
  role ("one biller accounts for N of the credit notes") — and say names were withheld until the
  owner vouches or asks.

### Know which manipulation actually pays

`payout_inr = total_incl_gst_inr × share_pct ÷ 100`. The consultant earns on **what was billed**,
not on what the hospital collected. So:

- A **recorded discount or below-tariff override lowers the billed line**, and therefore lowers the
  consultant's payout too. It hurts both. A discount is weak evidence of collusion and strong
  evidence of a pricing or policy problem.
- Money that **never reaches the hospital but was already billed** — a refund, a credit note raised
  after the share was computed, or an item never billed at all — costs the hospital and leaves the
  consultant's money intact. **That** is the gap worth asking about, and it is the honest way to
  frame the owner's instinct.

Say this distinction in the report. It is the difference between a question and an insult.

### The six checks

Run only the ones the files support; say which were skipped and why.

1. **Credit notes by biller** — group `leakage.csv` where `kind = credit-notes` on `biller`: count,
   total, and each biller's share of all credit notes this month. Compare each biller to the median
   biller, not to zero. Ask: *"₹X in N credit notes were last raised by <name> — what were they
   for?"*
2. **Rate overrides by biller** — `kind = overrides`, sum `shortfall_inr`, count. These are lines
   billed below list. Ask which rate was applied and who approved it.
3. **Discounts with no reason** — rows where `notes` is blank, and rows where one phrase repeats
   across many lines. A discount with no recorded reason is the single most useful line in the file,
   because the reason is the control.
4. **Refunds by biller and mode** — count, value, and `mode`. The pack carries **no link from a
   refund back to the original receipt**, so you cannot tell whether the refund was ever received.
   Say that; do not imply it.
5. **A sub-head that looks loss-making** — join `revenue-by-sub-head.csv` (`category`, `sub_head`,
   `billed_inr`, `credit_notes_inr`, `net_inr`, `lines`) to `leakage.csv` on `category` and
   `sub_head`. A sub-head with heavy volume and heavy `shortfall_inr` is being sold below tariff.
   **The pack holds this month only** — you cannot see whether volume rose or price fell against
   last month. Say that instead of asserting a trend.
6. **The consultant side — only if `share_pct` is populated.** If `share_pct` is 0 on every line,
   the hospital has configured no share and **no consultant analysis is possible**: say so and
   stop. If it is populated, look for consultants whose lines sit on high-`share_pct` items that
   are also heavily overridden or credited, and whose payout held while the hospital's collection
   fell on the same encounters.

### Never, in this section

- Name a person as dishonest, as committing fraud, or as "responsible".
- Present a count or a share as proof. Fourteen credit notes are a question, not a finding.
- Compute or imply a consultant share when `share_pct` is 0. A rate the owner supplies may be
  shown, but only as a labelled what-if — never as the hospital's share.
- Compare this month to last month from this pack — it holds one month.
- Carry a personal mobile or address into the integrity section beyond the debtor follow-up list;
  the rest belongs in the appendix, if anywhere.

## The collection split

Report the month separately as **cash, digital, cheque/other, payor** — from the pack. Say which
account types you pooled into each, because the account names belong to the hospital and vary
between organisations.

## The bank statement — optional, and only for the deposit side

The pack carries **no bank or contra voucher and no UTR**, so it cannot show whether money
collected reached the bank. That is the one question a statement answers.

If the owner supplies a **PDF bank statement** for the account the hospital deposits into:

1. Take cash collected in the month from the day book; take digital receipts and payor
   settlements likewise.
2. Match deposits to the book **on date and amount** — there is no reference number to match on.
3. Report three figures: collected in the book, deposited in the statement, and the difference.
4. List every unmatched line and **ask** the owner to explain it. Do not assume what a line is.
   A deposit shortfall is a question, not a finding of theft.

If no statement is supplied, still deliver the PDF and state plainly on it: *the collection split
is from the books; deposits are not verified.*

## Best practice, said once and not repeated

- **One month at a time.** Do not compare a part-month against a full month.
- **A balance is not revenue.** `cash_inr` is money on hand at month end, not money earned.
- **Say what is unverified**, on the page, not in a footnote.
- **Ask, do not infer**, when a line does not reconcile.
- **Keep the answer with the pack** — the owner should be able to re-run next month and compare
  like for like.

## Output — a PDF

Produce a PDF named `financial-status-<org>-<YYYY-MM>.pdf` and write it into that month's folder,
`packs\<YYYY-MM>\`, so the pack, the PDF and the review travel together. With it, in order:

1. **The month** — billed, collected, outstanding, and the cash / digital / bank closing balances.
2. **Cash versus digital** — the split with the account types it was built from.
3. **Debtors** — count and total, the top ten with mobile, the top-five share, and the 90+ money.
   Payor dues sit beside it, aged.
4. **Leakage** — total, and the concentration: the party, category or biller that explains most of
   it, phrased as a question. The full ranking lives in the revenue-leakage skill.
5. **First calls** — the patients who are both a large debtor and in the leakage rows.
6. **Integrity questions** — opened by the bold caution above, then at most three, each one line of
   numbers and one question, each with a line saying what would explain it innocently. Names only
   for people the owner has not vouched for; vouched names carry the label. The section ends by
   asking the administrator to confirm or dismiss each one from what they know.
7. **Deposits** — the reconciliation, or the statement that it was not verified.
8. **What this pack cannot tell you** — from `quality.json`, in plain words.
9. **What to fix** — no more than five actions, each tied to a figure above.

## Building the PDF

Write a self-contained HTML file with an A4 print stylesheet, then convert it:

```
msedge --headless --print-to-pdf="financial-status-<org>-<YYYY-MM>.pdf" "file:///<path>/report.html"
```

If Edge is not found, open the HTML and say: **Ctrl+P → Save as PDF**. Same pattern the pack's own
`tools/report.py` documents. The HTML is disposable; the PDF and the ledger are not.

## The action ledger — the memory

Each monthly zip is new, so the ledger lives **outside** it, in a folder the doctor keeps:

```
%USERPROFILE%\Documents\Nice-HMS\
  actions.json                    THE memory. Create it the first month, never overwrite it.
  consultants.csv                 name,email[,share_pct] — supplied once by the hospital
  actions-reminders.ics           reminders for the open actions
  packs\<YYYY-MM>\                each month's pack, unzipped into its own folder
  reviews\actions-<YYYY-MM>.csv   this month's review, copied into that month's folder
```

**One month, one folder.** Every monthly zip carries the same inner names — `clinical-<from>.csv`,
`financial-<orgId>/day-book.csv`, and the rest differ only in the date. Unpacking two months into one
folder therefore *overwrites the older month without a word*. Unzip each pack into `packs\<YYYY-MM>\`
the day it arrives; never beside the previous month and never into the download folder. If the owner
has already unpacked into a shared folder, move the earlier months into their own folders **before**
reading anything. The folder name is the owner's label, not proof — open `manifest.json` and confirm
the period it claims.

**Beginning of every run:** if `actions.json` exists, read it before writing a single line, score
every `open` action against this month's pack, and ask the owner about each one. If it does not
exist, and the owner has reviewed before, say so — he may be in the wrong folder.

**Scoring:** recompute the action's `check.metric` from this month's files and record
*improved / unchanged / worse* with both numbers. That is what makes this memory and not a list.

**Asking:** one line per open action, and one of four answers — done, accepted (living with it),
disputed (the AI was wrong), dropped (no longer relevant). Record the answer and the owner's words
in `owner_note`. Never argue with an `accepted` or `disputed`.

Schema:

```json
{ "org": "Example Hospital", "schema": 1,
  "actions": [{
    "id": "A-2026-11-01",
    "opened": "2026-11",
    "title": "Collect the ten largest patient debts",
    "why": "top ten carry 42% of ₹18.4L outstanding; ₹6.1L is over 90 days",
    "do": ["Open the patient dues report for the month",
           "Call the ten largest accounts and note what each says",
           "Record the outcome against the account"],
    "check": { "metric": "debtors_top10_balance_inr", "at_open": 1840000 },
    "status": "open",
    "owner_note": "",
    "reviewed": ["2026-11"]
  }] }
```

- **At most five new actions a month.** Six is a report nobody reads.
- Every action carries a `check.metric` that this month's pack can compute, or it is not an action.
- `accepted` and `disputed` are permanent. Show an `accepted` action once a year, once.
- Name the **role**, not the person: "the billing user who raised these". A ledger outlives a job.
- No patient data in the ledger beyond the debtor call list — names, mobiles and balances there, and
  nothing else.

## Reminders — an .ics file, not an integration

**Never** connect to Google Calendar or Tasks from a client-facing app: that needs OAuth, a
verified app, and a token that lives on a shared hospital PC.

Write `actions-reminders.ics` beside the ledger instead. One all-day event per `open` action, dated
the first of next month, `UID` stable per action id so re-importing updates rather than duplicates:

```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Nice HMS//financial-status//EN
BEGIN:VEVENT
UID:A-2026-11-01@nicehms
DTSTAMP:20261123T000000Z
DTSTART;VALUE=DATE:20261201
SUMMARY:Collect the ten largest patient debts
END:VEVENT
END:VCALENDAR
```

The owner double-clicks it; Google Calendar, Outlook or Apple Calendar imports it. Escape `,`, `;`
and newlines in `SUMMARY` per RFC 5545. **Never email this file to anyone** — it is the owner's.

## Payout sheets — produced, never sent

One **workbook per consultant**: `payout-<org>-<YYYY-MM>-<consultant>.xlsx`, six sheets. A payout is
read as a workbook — summary, detail, what is still owed to us, what we are paying late, and how it
left the bank — so a flat CSV cannot carry it. Write it with the kit's `xlsx` writer (stdlib only,
no package to install); if no runtime can be found, fall back to one CSV per sheet with the sheet
name as a suffix and say the workbook could not be built.

| # | Sheet | From | Carries |
|---|---|---|---|
| 1 | Summary | `consultant-payable.csv` | base (billed incl. GST), share, gross payout, less TDS, net payable, pending payor money |
| 2 | Line items | `consultant-payout-detail.csv` | patient name, UHID, encounter id, admission and discharge dates, item, quantity, charged, `total_incl_gst_inr`, `share_pct`, payout — grouped by encounter |
| 3 | By item type | `consultant-payout-detail.csv` | `category` / `sub_head`: lines, quantity, billed, share, payout |
| 4 | Pending from payors | `pending-payor-payout.csv` | unpaid insurer/TPA/PMJAY bills, amount held, and the month it may land — money **not** in this payout |
| 5 | Prior-period paid now | `encounters.csv` | encounters whose `revenue_month_inr` is 0 and `collection_month_inr` is not — billed in an earlier month, settled this one |
| 6 | Disbursement | the owner | mode (cash / bank / cheque), amount, UTR, TDS section and amount, net — **only what the owner supplies** |

- Banner on every sheet: *base is billed value including GST; the share shown is the one recorded, or
  assumed; this is not an instruction to pay.*
- **TDS is the owner's rate**, never an assumption: an assumed section or rate is worse than a blank.
  Same for the UTR — the pack carries none, so sheet 6 records what the owner gives and stays empty
  otherwise.
- Where `share_pct` is 0, the payout columns are **blank, not zero**, and marked *share not
  configured* — the work is still shown, the money is not invented.
- Sheet 2 carries patient names because the consultant treated those patients. Keep it to name, UHID
  and encounter — no mobile, no address, nothing the payout needs.
- The skill **does not send**. Whatever sends it must send **one message per consultant** — never one
  message with many attachments, and never a BCC batch, which puts every consultant's pay in one
  message.
- Say the sending tool must use a deterministic message id per month and consultant, and log each
  recipient's result, so a retry cannot pay out twice.
- If `consultants.csv` is missing, still write the per-consultant workbooks and say plainly that no
  email addresses were available, so nothing can be sent.

Then write `payout-mail-list.csv` (`consultant,email,file`) from `consultants.csv`.

## SOPs

Every action's `do` is a numbered procedure of **three to seven steps** that a manager can follow
without the AI present. Use only screens the owner can find in his own system; if the exact path is
unknown, say "in your billing module" rather than inventing a menu name.

## Never

- Present a lifetime column difference as an opening balance.
- Treat a name as a key when grouping.
- Fill a missing number with a guess.
- Build the payment split from the free-text `mode` column alone.
- Present an unmatched deposit as a finding until the owner has explained it.
- Print the whole debtors list — ten names and the concentration, not a phone book.
- Name a biller as responsible for a discount. Name them as the person to ask.
- Drop the bold line that these are AI-generated suspicions which may be wrong and must be checked
  with the administrator's real-world knowledge.
