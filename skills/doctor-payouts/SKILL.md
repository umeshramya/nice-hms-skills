---
name: doctor-payouts
description: Use when the user asks what each consultant earned versus what they were paid, or wants a labelled what-if on doctor payouts from a Nice HMS financial pack.
---

# Doctor payouts

Answer "did each consultant get paid in line with what they brought in?" — and make clear it is a
**what-if**, not a payout order.

## Read

- In each `financial-<orgId>/` folder: `consultant-payout-detail.csv` — one line per consultant per
  encounter.
- `tools/payout-rates.csv` if the user wants to apply their own shares.

## How to work out a payout

- The base for each line is the **amount including GST**.
- Apply the rate the user supplies: either one assumed share for all, or the per-consultant /
  per-item shares from `tools/payout-rates.csv`.
- A consultant with no matching rate is **left blank and listed as unmatched** — never zeroed.

## Output

- Per consultant: earned, rate applied, what-if payout, and a flag where no rate matched.
- A banner at the top: **the rates are assumed, not the hospital's configured shares.**
- Where the pack does not carry a consultant's actual share, say so.

## Never

- Present the result as what the hospital should pay.
- Invent a rate to make the table look complete. Blank is the correct answer.
- Match consultants by raw name — normalise, or use the id where present.
