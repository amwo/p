# General Rules

## Information Currency

ALWAYS refer to the latest information:
- Before starting implementation or configuration work, check official documentation when it exists
- Use MCP tools (context7, official docs servers) to fetch up-to-date documentation
- Do not rely solely on training data when current docs are available
- Verify version-specific details against official sources
- When library/framework versions matter, confirm the latest stable version before proceeding

## Fundamental Improvement

ALWAYS look beyond the immediate symptom:
- Clarify the essential problem before implementing
- Prefer root-cause fixes over superficial patches
- Choose the smallest scoped change that materially improves the underlying design
- Avoid local optimizations that make the broader system harder to maintain

## Post-Modification Checklist

ALWAYS perform after completing modifications:

1. **Plan Review**: When an implementation plan is created, if `codex` CLI is available, delegate a review to Codex and incorporate feedback to refine the plan before proceeding
2. **Regression Check**: Verify that changes do not introduce new bugs — run the full test suite and inspect related modules for unintended side effects
