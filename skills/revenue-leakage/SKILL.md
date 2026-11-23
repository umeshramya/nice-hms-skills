---
name: revenue-leakage
description: Use when the user asks where the hospital is losing money — discounts, waivers, unbilled services, rate drift — or wants the causes ranked by amount.
---

# Revenue leakage

Show where billed money was **not collected**, ranked by what it costs.

## Read

In each `financial-<orgId>/` folder:

- `leakage.csv` — lines where money billed was not collected, with the cause where the pack
  attributes one.

## Output

1. Total leaked, and leaked as a share of billed.
2. The **top three causes**, each with the row count and the amount, so the reader sees how much of
   the total it explains.
3. Anything the pack could not attribute to a cause — listed separately as **unexplained**.

## Never

- Invent a cause for a row the pack does not explain.
- Add "leakage" across organisations without saying which organisation each part came from.
- Present a discount as theft: a discount the owner granted is a decision, not an error. Say what
  it cost, and leave the judgement to them.
