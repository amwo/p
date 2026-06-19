---
name: improve
description: Self-regulating loop for ITERATIVE optimization toward a measurable objective. Auto-use whenever the task is to repeatedly improve something with a numeric metric until it is good enough — e.g. "maximize/minimize X", "keep improving until", "make the strategy profitable", "get the benchmark faster/smaller", "raise the test pass rate or coverage", "reduce latency", or any run under /loop or a Codex goal. NOT for one-shot edits or a single fix. On first run it auto-detects the project and scaffolds .improve/config.json (the user only confirms the metric command), then drives loop-ctl: ratchet on verified gains, pivot when an axis stalls, re-attack from a new angle when all stall, and stop only on budget or convergence. Invoke as /improve or via /loop /improve.
user-invocable: true
---

# Regulated improvement loop

You are running ONE iteration of a disciplined optimization loop governed by the
`loop-ctl` controller. The controller — not you — decides the search direction
and when to stop. Your job each iteration: execute exactly one well-scoped change
and report its measured score honestly.

## First run: auto-scaffold the config (do NOT make the user hand-write JSON)

If `.improve/config.json` is absent, DERIVE it from the project and the user's
goal, then show it for a quick confirm — never ask them to author it from scratch:

1. **objective** — restate the user's goal in one line.
2. **evaluator** — detect the project's metric command. It must print ONE number
   to stdout (higher = better) and be comparable across runs:
   - JS/TS: a `package.json` script — test pass count, benchmark, bundle size, Lighthouse.
   - Rust: `cargo test` pass count, or `cargo bench` / criterion number.
   - Python: pytest pass count, or a benchmark script.
   - Otherwise: ask the user for the single command that prints the metric.
   For overfit-prone metrics (trading, ML) make it **out-of-sample / walk-forward,
   with costs** — the loop only accumulates gains the evaluator measures honestly.
3. **axes** — pick 4–8 genuinely different improvement directions for the domain.
4. Leave `budget` / `stall_k` / `noise_margin` / `global_patience` at loop-ctl's
   defaults unless the user cares (a partial config is fine; defaults fill the rest).
5. Write `.improve/config.json`, SHOW it, and get a **one-line confirmation of the
   `evaluator`** — the only field whose correctness the loop cannot self-check.
   Then run `loop-ctl init`.

Example (only `evaluator` + `axes` are really required):

```json
{
  "objective": "maximize out-of-sample Sharpe",
  "evaluator": "python backtest.py --walk-forward --with-costs --print sharpe",
  "axes": ["features", "model", "risk", "timeframe", "execution"]
}
```

Only fall back to asking the user when the right metric is genuinely ambiguous.

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
