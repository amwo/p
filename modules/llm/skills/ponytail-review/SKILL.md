---
name: ponytail-review
description: >
  Review code exclusively for avoidable complexity and unnecessary ownership.
  Use when reviewing diffs or files for over-engineering, unnecessary
  dependencies, duplicated standard-library behavior, speculative abstraction,
  excessive boilerplate, or when the user invokes ponytail review. This review
  complements normal correctness, security, and performance review; it does not
  replace them.
---

# Ponytail Review

Review only whether the code owns more than it needs to own. Do not perform a
general correctness review unless a finding is directly caused by unnecessary
complexity.

## Review Order

1. Identify the requirement the diff is trying to satisfy.
2. Check whether the feature needs to exist now.
3. Check for existing codebase, standard library, platform, or installed
   dependency replacements.
4. Check for abstractions with one real implementation or one caller.
5. Check whether a smaller local implementation would be clearer.
6. Separate complexity findings from correctness, security, and performance
   findings.

## Finding Format

Use one line per finding:

`<file>:L<line>: <tag>: <what to remove>. <what replaces it>.`

Tags:

- `delete:` remove dead code, unused flexibility, or speculative features.
- `stdlib:` replace hand-rolled behavior with a standard library feature.
- `native:` replace code or dependencies with platform capability.
- `existing:` reuse a helper, component, type, or dependency already present.
- `yagni:` remove an abstraction, option, layer, or configuration with no
  current need.
- `shrink:` keep the behavior but express it with less code.

## Boundaries

- Do not flag trust-boundary validation as bloat.
- Do not flag security, privacy, audit, or authorization checks as bloat.
- Do not flag accessibility basics as bloat.
- Do not flag a focused regression test or smoke test as bloat.
- Do not apply fixes in this review; list what to cut and what replaces it.

If there is nothing meaningful to remove, report exactly:

`Lean already. Ship.`

Otherwise end with:

`net: -<estimated lines> lines possible.`
