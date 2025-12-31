# Rust Testing

> This file extends [common/testing.md](../common/testing.md) with Rust specific content.
> Based on [The Rust Book](https://doc.rust-lang.org/book/ch11-00-testing.html).

## Unit Tests

Place in the same file with `#[cfg(test)]`:

```rust
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 2), 4);
    }

    #[test]
    #[should_panic(expected = "overflow")]
    fn test_overflow() {
        add(i32::MAX, 1);
    }
}
```

## Integration Tests

Place in `tests/` directory:

```
src/
  lib.rs
tests/
  integration_test.rs
  common/
    mod.rs  # shared test utilities
```

```rust
// tests/integration_test.rs
use my_crate::public_api;

#[test]
fn test_public_api() {
    let result = public_api();
    assert!(result.is_ok());
}
```

## Property-Based Testing

Use `proptest` for generative testing:

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_parse_roundtrip(s in "\\PC*") {
        let parsed = parse(&s)?;
        let serialized = serialize(&parsed);
        prop_assert_eq!(s, serialized);
    }
}
```

## Test Runner

Use `cargo-nextest` for faster test execution:

```bash
cargo install cargo-nextest
cargo nextest run
```
