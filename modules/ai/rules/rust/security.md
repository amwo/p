# Rust Security

> This file extends [common/security.md](../common/security.md) with Rust specific content.
> Based on [RustSec Advisory Database](https://rustsec.org/) and Rust Secure Code Working Group.

## Dependency Auditing

Use `cargo-audit` to check for known vulnerabilities:

```bash
cargo install cargo-audit
cargo audit
```

Use `cargo-deny` for comprehensive checks:

```bash
cargo install cargo-deny
cargo deny check
```

## Minimize Unsafe Code

```rust
// WRONG: Unsafe without justification
unsafe {
    ptr::write(dest, value);
}

// CORRECT: Document safety invariants
// SAFETY: `dest` is valid, aligned, and not aliased
unsafe {
    ptr::write(dest, value);
}
```

## Integer Overflow

Enable overflow checks in release builds:

```toml
# Cargo.toml
[profile.release]
overflow-checks = true
```

Use checked arithmetic:

```rust
// WRONG: Silent overflow in release
let result = a + b;

// CORRECT: Explicit handling
let result = a.checked_add(b).ok_or(Error::Overflow)?;
```

## Cryptography

Use audited libraries:

- `ring` - TLS, cryptographic primitives
- `rustls` - TLS implementation
- `RustCrypto` - algorithm implementations

```rust
use ring::rand::{SecureRandom, SystemRandom};

let rng = SystemRandom::new();
let mut key = [0u8; 32];
rng.fill(&mut key)?;
```

## Input Validation

Validate at system boundaries:

```rust
pub fn process_input(input: &str) -> Result<Output, Error> {
    let validated = Input::parse(input)?;  // validate first
    // ... process validated input
}
```
