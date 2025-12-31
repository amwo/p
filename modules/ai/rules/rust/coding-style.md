# Rust Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Rust specific content.
> Based on [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/) and [Clippy](https://doc.rust-lang.org/clippy/).

## Formatting

Use `rustfmt` for consistent formatting:

```bash
cargo fmt --all
cargo fmt --all -- --check  # CI
```

## Linting

Use `clippy` with recommended lints:

```bash
cargo clippy -- -D warnings
cargo clippy -- -D clippy::all -D clippy::pedantic
```

### Recommended Clippy Lints

```rust
#![warn(clippy::all, clippy::pedantic)]
#![deny(clippy::unwrap_used, clippy::expect_used)]
#![allow(clippy::module_name_repetitions)]
```

## Error Handling

Never use `unwrap()` or `expect()` in library code:

```rust
// WRONG: May panic
let value = option.unwrap();
let result = fallible_op().expect("failed");

// CORRECT: Propagate errors
let value = option.ok_or(MyError::NotFound)?;
let result = fallible_op()?;

// CORRECT: Pattern matching
if let Some(value) = option {
    process(value);
}
```

## Ownership

Prefer borrowing over cloning:

```rust
// WRONG: Unnecessary clone
fn process(data: Vec<u8>) { ... }
process(my_data.clone());

// CORRECT: Borrow when possible
fn process(data: &[u8]) { ... }
process(&my_data);
```

## Naming Conventions

- Types: `PascalCase`
- Functions/methods: `snake_case`
- Constants: `SCREAMING_SNAKE_CASE`
- Lifetimes: short lowercase (`'a`, `'de`)
- Conversions: `as_`, `to_`, `into_` prefixes
