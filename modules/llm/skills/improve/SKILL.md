---
name: improve
description: Run a self-regulating improvement loop toward a measurable objective. Use when iterating with /loop or a Codex goal to improve something that has a numeric metric (test pass rate, benchmark, latency, trading PnL, rubric score) and you want guaranteed progress instead of endless ineffective tweaks. Drives the loop-ctl controller — ratchet on verified gains, pivot when an axis stalls, re-attack from a new angle when all stall, and stop only on budget or convergence. Invoke as /improve or via /loop /improve.
user-invocable: true
---

# Regulated improvement loop

You are running ONE iteration of a disciplined optimization loop governed by the
`loop-ctl` controller. The controller — not you — decides the search direction
and when to stop. Your job each iteration: execute exactly one well-scoped change
and report its measured score honestly.

## One-time setup (first run only)

If `.improve/config.json` does not exist, create it, then run `loop-ctl init`.

```json
{
  "objective": "human-readable goal, e.g. maximize out-of-sample Sharpe",
  "evaluator": "shell command that prints ONE number to stdout; higher = better",
  "axes": ["features", "model", "risk", "timeframe", "execution"],
  "budget": 50,
  "stall_k": 4,
  "noise_margin": 0.0,
  "global_patience": 2
}
```

- `evaluator` MUST be trustworthy and comparable across runs. For anything prone
  to overfitting (trading, ML), make it **out-of-sample / walk-forward, with
  transaction costs**, and ideally penalize multiple testing (e.g. deflated
  Sharpe). The loop can only "reliably accumulate" gains the evaluator measures
  honestly — a misleading metric makes every improvement fake.
- `axes` are the genuinely different angles the controller rotates through when
  one stalls. List 4–8.

## Each iteration (this is what /loop repeats)

1. **Ask the controller:** run `loop-ctl next` and read the JSON directive.
2. **If `action == "stop"`:** run `loop-ctl status`, summarize the best result,
   and end the loop. Do not keep tweaking.
3. **Otherwise:** make **exactly ONE** change along the directive's `axis`.
   `regime` tells you how: `exploit` = refine the current best, `pivot` = a fresh
   axis, `explore` = re-attack from a new angle. Stay within that axis.
4. **Measure:** run the `evaluator` and capture the numeric score.
5. **Record:** `loop-ctl record --axis <axis> --score <N> --hypothesis "<what you changed>"`.
6. **Never claim success** unless the recorded score beat the previous best (the
   controller's ratchet sets `accepted`). A rejected result is expected data —
   after `stall_k` misses the controller pivots for you.

## Rules

- Follow the controller's `axis`/`action`. Do not free-style or stop early
  because one direction isn't working: stalling triggers an automatic pivot, and
  total stalling triggers a fresh-angle explore. The loop never gives up on a
  single stalled axis — only on budget or global convergence.
- One change per iteration, so each score is attributable.
- Keep changes reversible (git/commit per accepted step) so rejected experiments
  roll back cleanly.
- A Stop-hook backstop refuses a premature stop while the controller still says
  continue, so the loop keeps pivoting instead of giving up.
