# TypeScript/JavaScript フック

> このファイルは [common/hooks.md](../common/hooks.md) を TypeScript/JavaScript 固有の内容で拡張したものです。

## PostToolUse フック

`~/.claude/settings.json` で構成します：

- **Prettier**: JS/TS ファイルの編集後に自動フォーマット。
- **TypeScript check**: `.ts`/`.tsx` ファイルの編集後に `tsc` を実行。
- **console.log warning**: 編集されたファイル内の `console.log` について警告。

## Stop フック

- **console.log audit**: セッション終了前に、すべての変更されたファイルで `console.log` をチェック。
