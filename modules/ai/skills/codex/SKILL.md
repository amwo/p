---
name: codex
description: Delegate tasks to OpenAI Codex CLI agent. Use when the user asks to run something with Codex, get a second opinion from another AI, or delegate a subtask to Codex. Typical queries include "run this with codex", "ask codex to review", "have codex implement", "codex opinion on".
allowed-tools: Bash, Read, Glob, Grep
user-invocable: true
disable-model-invocation: true
---

# Codex CLI Integration

Delegate tasks to the OpenAI Codex CLI (`codex exec` / `codex review`).

## Usage

### `/codex <prompt>`

Run `codex exec` with the given prompt.

Steps:
1. Parse `$ARGUMENTS` for the prompt
2. If `$ARGUMENTS` starts with `review`, run `codex review` instead of `codex exec`
3. Run the command with `--full-auto`
4. Capture and return the output
5. Summarize the result for the user

### Subcommands

- **`/codex <prompt>`** — execute a task
- **`/codex review`** — review uncommitted changes
- **`/codex review --base main`** — review changes vs base branch

### Model Selection

Append `-m <model>` in arguments to override the default model.

### Examples

```
/codex implement a retry mechanism for the HTTP client
/codex review the changes in executor.rs
/codex -m o3 explain the backtest engine architecture
```

## Execution Template

```bash
# Task execution (default model)
codex exec --full-auto -C "$(pwd)" "$PROMPT"

# Task execution (specific model)
codex exec --full-auto -m o3 -C "$(pwd)" "$PROMPT"

# Code review (uncommitted changes)
codex review --uncommitted "$PROMPT"

# Code review (vs base branch)
codex review --base main "$PROMPT"
```

## Important

- Always use `--full-auto` for non-interactive execution
- Use `-C <dir>` to set the working directory to the current project
- Set timeout to 300000 (5 min) for complex tasks
- Output may be long; summarize key findings for the user
- Codex writes to the filesystem; review its changes before accepting
