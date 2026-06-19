#!/usr/bin/env bash
# Stop-hook backstop for regulated improvement loops (loop-ctl / the `improve`
# skill). It does nothing unless a loop is active (.improve/active present). When
# active, it refuses a premature stop: if loop-ctl's latest directive still says
# "continue", it exits 2 so the agent keeps pivoting instead of giving up. The
# controller decides when to actually stop (budget / convergence), at which point
# the directive flips to "stop" and this guard steps aside.
set -uo pipefail

INPUT=$(cat)

# Re-entrancy guard: if we are already inside a stop-hook continuation, allow the
# stop so we never block forever.
if printf '%s' "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# Only act during an active loop.
[ -f .improve/active ] || exit 0

dir=.improve/directive.json
[ -f "$dir" ] || exit 0

action=$(jq -r '.action // empty' "$dir" 2>/dev/null)
if [ "$action" = "continue" ]; then
  axis=$(jq -r '.axis // ""' "$dir" 2>/dev/null)
  regime=$(jq -r '.regime // ""' "$dir" 2>/dev/null)
  printf 'Improvement loop is NOT converged (loop-ctl: continue, regime=%s, axis=%s). Do not stop — run `loop-ctl next` and execute the next /improve iteration.\n' "$regime" "$axis" >&2
  exit 2
fi

exit 0
