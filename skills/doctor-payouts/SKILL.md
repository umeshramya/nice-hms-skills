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
- `tools/payout-rates.csv` if the user wants to apply their own per-consultant / per-item shares.

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
- Apply the rate the user supplies: one assumed share for all, or the per-consultant / per-item
  shares from `tools/payout-rates.csv`. Payout = base × rate. A negative line gives a negative
  payout — that is correct.
- A consultant with no matching rate is **left blank and listed as unmatched** — never zeroed.

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
figure was reached and a wrong range fails loudly. The rate sits in one cell; each payout cell is
`=IF(<rate>="","",ROUND(<total>*<rate>,2))` so a no-share line stays **blank**, not 0; totals are
`=SUM(...)` over the full range, which pulls the negative reversal lines in by design; and a
Python-computed **control total** sits beside each `SUM` with a Check cell
(`=IF(ABS(<sum>-<control>)<0.005,"OK","MISMATCH")`). See the *Formula contract* in the
`financial-status` skill for the exact templates and the no-cached-value caveat.

## Output

- Per consultant: earned, rate applied, what-if payout, and a flag where no rate matched.
- A banner at the top: **the rates are assumed, not the hospital's configured shares.**
- Where the pack does not carry a consultant's actual share, say so. When `share_pct` is 0 on every
  line (a common pack), the recorded `payout_inr` is not computable: say that, and present the
  supplied-rate figure only as a labelled what-if.

## Never

- Present the result as what the hospital should pay.
- Invent a rate to make the table look complete. Blank is the correct answer.
- Match consultants by raw name — normalise, or use the id where present.
- Present a gross figure as net, or a net figure as gross. Say which side credit notes and refunds
  sit on.
