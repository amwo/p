---
name: ponytail
description: >
  High-quality minimal implementation discipline for coding tasks; use when
  writing, fixing, refactoring, reviewing, designing code, or choosing
  libraries and dependencies. Also use when the user says "ponytail", "YAGNI",
  "simplify", "minimal", "do less", "avoid over-engineering", or asks for the
  shortest maintainable path. Prefer not building, reusing existing code,
  standard library features, native platform capabilities, and already
  installed dependencies before adding new code or dependencies. Never use to
  remove required validation, security, error handling, accessibility, or
  verification.
---

# Ponytail

Use the smallest maintainable change that actually satisfies the request.
The goal is not clever brevity. The goal is high-quality code with fewer owned
parts, fewer dependencies, fewer abstraction layers, and clear verification.

## Work Order

1. Read the relevant code path before choosing an implementation.
2. Find the real boundary of the change: callers, data flow, side effects, and
   failure modes.
3. Apply the ladder below and stop at the first rung that works.
4. Implement only that rung.
5. Verify with the narrowest command that proves the change.

## Quality Ladder

1. Does this need to exist now?
   If the requirement is speculative, do not build it. State the reason.

2. Is it already in the codebase?
   Reuse an existing helper, component, type, pattern, or configuration before
   creating a new one.

3. Does the language or standard library already solve it?
   Prefer standard parsing, formatting, collection, date, path, and networking
   utilities over custom versions.

4. Does the platform already solve it?
   Prefer browser controls, CSS, database constraints, operating system
   behavior, framework conventions, and protocol guarantees over application
   code.

5. Does an existing dependency already solve it?
   Use what is already installed when it is a good fit. Add a dependency only
   when standard, platform, and existing project options are insufficient.

6. Can a small local implementation solve it clearly?
   Write the local code. Do not introduce a reusable abstraction until there
   are multiple real uses.

7. Only then, add the minimum new structure needed.
   Keep the scope narrow and document why simpler options were not enough.

## Non-Negotiables

- Do not remove validation at trust boundaries.
- Do not weaken authentication, authorization, privacy, security, or audit
  behavior.
- Do not remove error handling that prevents data loss or hides operational
  failures.
- Do not remove accessibility basics.
- Do not skip verification for non-trivial behavior.
- Do not ignore explicit user requirements. If the user insists on a larger
  implementation, build it with the same quality bar.

## Implementation Rules

- Prefer deletion over addition when behavior remains correct.
- Avoid single-use interfaces, factories, wrappers, registries, and
  configuration.
- Avoid "future-proof" options until there is a current caller or requirement.
- Keep changes in the smallest set of files that matches the existing design.
- For bug fixes, fix the shared root cause rather than patching one symptom
  path.
- For new dependencies, record the reason standard, platform, and existing
  dependency options are insufficient.
- Add a `ponytail:` comment only when a deliberate shortcut has a known ceiling
  and a clear upgrade condition.

## Verification

Trivial one-line changes may need only a focused inspection. Non-trivial logic
needs the smallest runnable check that would fail if the behavior regressed:
an existing test, a focused new test, or a small self-check that matches the
project's conventions.

Do not add large test scaffolding only to satisfy this skill. Use the existing
test shape unless the project has none.

## Reporting

After the code, report only what matters:

- what changed
- what was intentionally not added
- what command verified it
- when the omitted complexity should be added later, if applicable
