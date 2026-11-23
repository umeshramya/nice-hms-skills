---
name: dues-aging
description: Use when the user asks who owes the hospital money, how much is outstanding at month end, or how old the dues are — split between patients and payors.
---

# Dues and aging

Split what is owed into the two places it actually sits: **patients** and **payors**.

## Read

In each `financial-<orgId>/` folder:

- `debitors.csv` — outstanding at month end.
- `insurance-due.csv` — payor outstanding.
- `aging.csv` — how old each balance is.
- `pending-payor-payout.csv` — payor bills still unpaid on this month's encounters, and the
  consultant money held against them.

## Output

1. **Patient dues** — total, and the aged buckets (0–30 / 31–60 / 61–90 / 90+).
2. **Payor dues** — total, aged the same way, naming the largest payors.
3. **Held against unpaid claims** — the consultant money tied up in pending payor payouts.
4. **Where the split cannot be drawn** — say so, rather than forcing a patient/payor allocation.

## Never

- Add a lifetime column into a month-end balance.
- Assume a balance is patient's when the file attributes it to a payor, or the reverse.
- Present an overdue figure as uncollectable without the user saying so.
