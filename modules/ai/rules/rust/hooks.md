# Rust Hooks

> This file extends [common/hooks.md](../common/hooks.md) with Rust specific content.

## Pre-commit Hook

```bash
#!/bin/sh
set -e

# Format check
cargo fmt --all -- --check

# Lint
cargo clippy -- -D warnings

# Security audit
cargo audit

# Tests
cargo test --all
```

## CI Pipeline

```yaml
# .github/workflows/rust.yml
name: Rust CI

on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt, clippy

      - name: Format
        run: cargo fmt --all -- --check

      - name: Clippy
        run: cargo clippy -- -D warnings

      - name: Test
        run: cargo test --all

      - name: Audit
        run: |
          cargo install cargo-audit
          cargo audit
```

## Recommended Tools

```bash
# Install development tools
cargo install cargo-audit    # security audit
cargo install cargo-deny     # dependency checks
cargo install cargo-nextest  # fast test runner
cargo install cargo-watch    # auto-rebuild on changes
```

## Watch Mode

```bash
# Auto-run tests on file changes
cargo watch -x test

# Auto-run clippy
cargo watch -x clippy
```
