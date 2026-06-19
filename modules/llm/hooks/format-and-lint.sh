#!/usr/bin/env bash
# PostToolUse hook: after the agent edits a file, format it silently and lint
# with --fix. Formatting never blocks; remaining lint problems exit 2 so their
# stderr is fed back to the model (PostToolUse cannot undo the edit, but the
# agent sees the errors and fixes them on the next turn).
#
# Gating is done in-script by extension because a hook matcher can only filter
# by tool name, not file path. stdin is the tool-event JSON; the edited path is
# at .tool_input.file_path (Claude) or .tool_input.path (Codex).
set -uo pipefail

INPUT=$(cat)
# Recursively pull the edited path from any harness schema (Claude/Codex nest it
# under tool_input; Cursor puts file_path at top level; Gemini uses absolute_path).
FILE=$(printf '%s' "$INPUT" | jq -r '[.. | objects | .file_path?, .path?, .absolute_path?] | map(select(type == "string")) | .[0] // empty')

# Nothing actionable (no path, or file was deleted).
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 0

dir=$(dirname "$FILE")

case "$FILE" in
  *.js | *.jsx | *.ts | *.tsx | *.mjs | *.cjs | *.json | *.css | *.scss | *.md)
    # Format silently with the project-local prettier; never block on format diffs.
    (cd "$dir" && npx --no-install prettier --write "$FILE") >/dev/null 2>&1 || true

    # Lint + autofix only the script extensions; surface remaining problems.
    case "$FILE" in
      *.js | *.jsx | *.ts | *.tsx | *.mjs | *.cjs)
        if ! OUT=$(cd "$dir" && npx --no-install eslint --fix "$FILE" 2>&1); then
          printf 'eslint reported problems in %s:\n%s\n' "$FILE" "$OUT" >&2
          exit 2
        fi
        ;;
    esac
    ;;

  *.rs)
    # Format the single file silently.
    rustfmt --edition 2021 "$FILE" >/dev/null 2>&1 || true

    # clippy is crate-scoped; cargo walks up from the file's dir to the crate root.
    if command -v cargo >/dev/null 2>&1; then
      if ! OUT=$(cd "$dir" && cargo clippy --quiet --all-targets --message-format short 2>&1); then
        printf 'cargo clippy reported problems:\n%s\n' "$OUT" >&2
        exit 2
      fi
    fi
    ;;
esac

exit 0
