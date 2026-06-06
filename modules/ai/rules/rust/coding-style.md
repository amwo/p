# Rust フック

> このファイルは [common/hooks.md](../common/hooks.md) を Rust 固有の内容で拡張したものです。

## Pre-commit フック

```bash
#!/bin/sh
set -e

# フォーマットチェック
cargo fmt --all -- --check

# リンティング
cargo clippy -- -D warnings

# セキュリティ監査
cargo audit

# テスト
cargo test --all
```

## CI パイプライン

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

## 推奨ツール

```bash
# 開発ツールのインストール
cargo install cargo-audit    # セキュリティ監査
cargo install cargo-deny     # 依存関係チェック
cargo install cargo-nextest  # 高速なテストランナー
cargo install cargo-watch    # 変更時の自動再ビルド
```

## ウォッチモード

```bash
# ファイル変更時にテストを自動実行
cargo watch -x test

# clippy を自動実行
cargo watch -x clippy
```
(clone) よりも借用 (borrowing) を優先してください：

```rust
// 間違い: 不要なクローン
fn process(data: Vec<u8>) { ... }
process(my_data.clone());

// 正しい: 可能な限り借用する
fn process(data: &[u8]) { ... }
process(&my_data);
```

## 命名規則

- 型 (Types): `PascalCase`
- 関数/メソッド: `snake_case`
- 定数: `SCREAMING_SNAKE_CASE`
- ライフタイム: 短い小文字 (`'a`, `'de`)
- 変換: `as_`, `to_`, `into_` プレフィックス
