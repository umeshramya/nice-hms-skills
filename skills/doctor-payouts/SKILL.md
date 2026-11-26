---
name: doctor-payouts
description: Use when the user asks what each consultant earned versus what they were paid, or wants a labelled what-if on doctor payouts from a Nice HMS financial pack.
---

# Doctor payouts

Answer "did each consultant get paid in line with what they brought in?" — and make clear it is a
**what-if**, not a payout order.

## Read

- In each `financial-<orgId>/` folder: `consultant-payout-detail.csv` — one line per consultant per
  encounter. Columns: `consultant, encounter_id, encounter, item, rate_inr, quantity,
  total_incl_gst_inr, share_pct, payout_inr`.
- `financial-<orgId>/leakage.csv` and `financial-summary.csv` — only to corroborate a credit note
  (see *Credit notes and refunds*), never to deduct from a base a second time.
- `tools/payout-rates.csv` — the hospital's own shares, optional: `consultant,item,share_pct`
  (`75` = 75%; blank `consultant` or `item` is a wildcard). It lives at `<project>\tools\payout-rates.csv`;
  the kit ships a header-only template to copy there. Read it when it exists: it fills lines the pack
  left with no share, and never overrides one the pack recorded. Missing or empty is normal — say so
  rather than assuming every line is at the supplied rate.

## The calculation, exactly

- **The base is `sum(total_incl_gst_inr)` over the consultant's rows, with the negative rows
  included.** That total is already net of credit notes — the pack carries each credit note as a
  negative reversal line, not as a separate deduction.
- **Never `abs()` the money column, never drop negative rows, never rebuild gross from the invoice
  lines alone.** Any of those re-grosses the base and overpays.
- **Do not compute a line from `rate_inr × quantity`.** On a reversal line both stay positive while
  only `total_incl_gst_inr` is negative — so `rate × qty` silently adds the reversed money back.
  Use `total_incl_gst_inr` for every amount.
- **A reversal line yields a negative payout line. Show it, negative.** It is the clawback; do not
  floor it at zero, and do not hide it inside a "net" total with no line behind it.
- `quantity` is not signed on a reversal line either. A quantity total does **not** net by summing;
  compute net qty as `sum(qty where total > 0) − sum(qty where total < 0)`, or show invoices and
  reversals as separate counts.
- Payout = base × the share that applies to that line. A negative line gives a negative payout —
  that is correct.

## Which share applies — a recorded share is never overridden

Resolve the share **per line**, most specific first. Stop at the first that exists:

1. **The share the pack records** — `share_pct` on that line in `consultant-payout-detail.csv`,
   when it is greater than zero. **This must be honoured exactly as recorded.** Do not replace it
   with an assumed rate, do not average it with one, do not "smooth" it to a round number.
2. **The hospital's rate file** — `tools/payout-rates.csv` (columns `consultant,item,share_pct`;
   `share_pct` is a percentage, `75` = 75%; a blank `consultant` or `item` is a wildcard). Match
   consultant + item first, then consultant alone, then item alone.
3. **The rate the user supplies** — one assumed share for every line still unresolved.
4. **Nothing** — leave the line's payout **blank** and list it as unset. Blank is the correct
   answer; never invent a rate and never write 0.

Consequences that follow, and that the report must state:

- A mixed workbook is normal: some lines at a recorded share, the rest at the assumed one. Label
  each line with its **basis** (`pack` / `rates file` / `assumed`) and show the applied share next
  to the recorded one, so the admin can see which lines were taken from the pack and which are the
  what-if.
- When `share_pct` is 0 on **every** line, the pack carries no share at all and the recorded
  `payout_inr` is not computable. Say that plainly; the supplied rate is then the only figure and
  must be labelled assumed.
- A consultant with no share from any source is **left blank and listed as unmatched** — never
  zeroed.
- If a line's `share_pct` and its recorded `payout_inr` disagree with each other, report both and
  say they disagree. Do not pick one silently.

## Credit notes and refunds are different money

- **A credit note reverses revenue already billed.** In the payout detail it is a negative line, so
  it lowers the base and therefore the payout. It also lowers billed revenue and outstanding in
  `financial-summary.csv`.
- **A refund returns a payment already received.** It is money out: it lowers collections and cash,
  and it touches **neither billed revenue nor the payout base**. Never subtract a refund from a
  consultant's base.

Do not double-deduct. The base from the detail file is already net of the credit note; the matching
row in `leakage.csv` (`kind = credit-notes`) is the same money. Use it to *check* the reversal — the
negative detail lines for an encounter should sum to that encounter's credit-note amount — not to
subtract again. Where `encounter_id` is populated on the leakage row, tie it to the detail
`encounter_id`.

## The workbook shows its arithmetic

Build the payout workbook with live formulas, not baked numbers, so the admin can see how each
figure was reached and a wrong range fails loudly. The share chain is **two visible cells**, not one:

- *share applied* — `=IF(AND(ISNUMBER(Hn),Hn>0),Hn,IF(Summary!$B$3="","",Summary!$B$3*100))`: the
  share recorded on the line wins, the assumed rate fills the gap, and a blank rate stays blank.
- *payout* — `=IF(In="","",ROUND(Gn*In/100,2))` so no-share stays **blank**, never 0.

Totals are `=SUM(...)` over the full range, which pulls the negative reversal lines in by design; a
Python-computed **control total** sits beside each `SUM` with a Check cell
(`=IF(ABS(<sum>-<control>)<0.005,"OK","MISMATCH")`); and the summary splits the payout into the
honoured-share part and the assumed part, each with its own control. See the *Formula contract* in
the `financial-status` skill for the exact templates and the no-cached-value caveat.

## Output

- Write each workbook and the mail list into the project's **`out\`** folder — `<project>\out\`, the
  folder the monthly zip was extracted into, beside that month's PDF, never beside the pack CSVs and
  never in a central folder.
- Per consultant: earned, the share applied and where it came from, the payout, and a flag where no
  share was found at all.
- A banner at the top that says which of the two cases this is: **some lines are at the hospital's
  recorded share and the rest are assumed**, or **the pack records no share on any line, so every
  figure here is assumed**. Never print a blanket "assumed" banner over honoured lines.
- Where the pack does not carry a consultant's actual share, say so. When `share_pct` is 0 on every
  line, the recorded `payout_inr` is not computable: say that, and present the supplied-rate figure
  only as a labelled what-if.

## Never

- Present the result as what the hospital should pay.
- Override a share the pack records with the assumed rate, or average a mixed set into one rate.
  A recorded share is the hospital's own figure; the assumed rate only fills the lines it left empty.
- Invent a rate to make the table look complete. Blank is the correct answer.
- Match consultants by raw name — normalise, or use the id where present.
- Present a gross figure as net, or a net figure as gross. Say which side credit notes and refunds
  sit on.
