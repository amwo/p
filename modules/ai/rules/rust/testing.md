# Rust テスト

> このファイルは [common/testing.md](../common/testing.md) を Rust 固有の内容で拡張したものです。
> [The Rust Book](https://doc.rust-lang.org/book/ch11-00-testing.html) に基づいています。

## ユニットテスト

`#[cfg(test)]` を使用して同じファイル内に配置します：

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

## 統合テスト

`tests/` ディレクトリに配置します：

```
src/
  lib.rs
tests/
  integration_test.rs
  common/
    mod.rs  # 共有テストユーティリティ
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

## プロパティベーステスト (Property-Based Testing)

生成テストのために `proptest` を使用してください：

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

## テストランナー

テスト実行を高速化するために `cargo-nextest` を使用してください：

```bash
cargo install cargo-nextest
cargo nextest run
```
