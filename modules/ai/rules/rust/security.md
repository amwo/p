# Rust セキュリティ

> このファイルは [common/security.md](../common/security.md) を Rust 固有の内容で拡張したものです。
> [RustSec Advisory Database](https://rustsec.org/) および Rust Secure Code Working Group に基づいています。

## 依存関係の監査

既知の脆弱性をチェックするために `cargo-audit` を使用してください：

```bash
cargo install cargo-audit
cargo audit
```

包括的なチェックには `cargo-deny` を使用してください：

```bash
cargo install cargo-deny
cargo deny check
```

## Unsafe コードの最小化

```rust
// 間違い: 正当な理由のない unsafe
unsafe {
    ptr::write(dest, value);
}

// 正しい: 安全性の不変条件を文書化する
// SAFETY: `dest` は有効で整列されており、エイリアスされていない
unsafe {
    ptr::write(dest, value);
}
```

## 整数オーバーフロー

リリースビルドでオーバーフローチェックを有効にしてください：

```toml
# Cargo.toml
[profile.release]
overflow-checks = true
```

チェック付き算術演算を使用してください：

```rust
// 間違い: リリースビルドでの黙ったオーバーフロー
let result = a + b;

// 正しい: 明示的な処理
let result = a.checked_add(b).ok_or(Error::Overflow)?;
```

## 暗号化

監査済みのライブラリを使用してください：

- `ring` - TLS、暗号プリミティブ
- `rustls` - TLS 実装
- `RustCrypto` - アルゴリズムの実装

```rust
use ring::rand::{SecureRandom, SystemRandom};

let rng = SystemRandom::new();
let mut key = [0u8; 32];
rng.fill(&mut key)?;
```

## 入力バリデーション

システムの境界でバリデーションを行ってください：

```rust
pub fn process_input(input: &str) -> Result<Output, Error> {
    let validated = Input::parse(input)?;  // 最初にバリデーション
    // ... バリデーション済み入力の処理
}
```
