---
name: codex
description: OpenAI Codex CLI エージェントにタスクを委任します。ユーザーが Codex で何かを実行するように依頼したとき、別の AI からセカンドオピニオンを得たいとき、またはサブタスクを Codex に委任したいときに使用します。典型的なクエリには、「これを codex で実行して」、「codex にレビューを依頼して」、「codex に実装させて」、「これについての codex の意見は」などがあります。
allowed-tools: Bash, Read, Glob, Grep
user-invocable: true
disable-model-invocation: true
---

# Codex CLI 統合

OpenAI Codex CLI (`codex exec` / `codex review`) にタスクを委任します。

## 使用法

### `/codex <prompt>`

指定されたプロンプトで `codex exec` を実行します。

手順：
1. `$ARGUMENTS` からプロンプトを解析する
2. `$ARGUMENTS` が `review` で始まる場合は、`codex exec` の代わりに `codex review` を実行する
3. `-a never -s workspace-write -c 'sandbox_workspace_write.network_access=true'` を付けてコマンドを実行する
4. 出力をキャプチャして返す
5. ユーザーのために結果を要約する

### サブコマンド

- **`/codex <prompt>`** — タスクを実行する
- **`/codex review`** — 未コミットの変更をレビューする
- **`/codex review --base main`** — ベースブランチとの変更の差分をレビューする

### モデルの選択

引数に `-m <model>` を追加して、デフォルトのモデルを上書きします。

### 例

```
/codex HTTP クライアントのリトライメカニズムを実装して
/codex executor.rs の変更をレビューして
/codex -m o3 バックテストエンジンのアーキテクチャを説明して
```

## 実行テンプレート

```bash
# タスクの実行 (デフォルトモデル)
codex -a never -s workspace-write -c 'sandbox_workspace_write.network_access=true' exec -C "$(pwd)" "$PROMPT"

# タスクの実行 (特定のモデル)
codex -a never -s workspace-write -c 'sandbox_workspace_write.network_access=true' exec -m o3 -C "$(pwd)" "$PROMPT"

# コードレビュー (未コミットの変更)
codex -a never -s workspace-write -c 'sandbox_workspace_write.network_access=true' review --uncommitted "$PROMPT"

# コードレビュー (ベースブランチとの比較)
codex -a never -s workspace-write -c 'sandbox_workspace_write.network_access=true' review --base main "$PROMPT"
```

## 重要事項

- 非対話的な実行には常に `codex -a never -s workspace-write -c 'sandbox_workspace_write.network_access=true' <subcommand>` の形を使用してください。
- 作業ディレクトリを現在のプロジェクトに設定するために `-C <dir>` を使用してください。
- 複雑なタスクの場合は、タイムアウトを 300000 (5分) に設定してください。
- 出力が長くなる可能性があるため、主要な発見事項をユーザーのために要約してください。
- Codex はファイルシステムに書き込みを行います。変更を受け入れる前にレビューしてください。
