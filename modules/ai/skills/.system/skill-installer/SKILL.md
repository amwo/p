---
name: skill-installer
description: Codex スキルを厳選リストまたは GitHub リポジトリのパスから $CODEX_HOME/skills にインストールします。ユーザーがインストール可能なスキルのリスト表示、厳選されたスキルのインストール、または別のリポジトリ（プライベートリポジトリを含む）からのスキルのインストールを依頼したときに使用します。
metadata:
  short-description: openai/skills または他のリポジトリから厳選されたスキルをインストールする
---

# スキルインストーラー (Skill Installer)

スキルのインストールを支援します。デフォルトでは https://github.com/openai/skills/tree/main/skills/.curated からインストールされますが、ユーザーは他の場所を指定することもできます。

タスクに基づいてヘルパースクリプトを使用してください：
- ユーザーが何が利用可能か尋ねた場合、またはユーザーが何をすべきか指定せずにこのスキルを使用した場合に、厳選されたスキルをリスト表示します。
- ユーザーがスキル名を提供した場合、厳選リストからインストールします。
- ユーザーが GitHub のリポジトリ/パス（プライベートリポジトリを含む）を提供した場合、別のリポジトリからインストールします。

ヘルパースクリプトを使用してスキルをインストールします。

## コミュニケーション

厳選されたスキルをリスト表示する際は、ユーザーのリクエストのコンテキストに応じて、おおよそ以下のように出力してください：
"""
{repo} からのスキル：
1. skill-1
2. skill-2 (インストール済み)
3. ...
どれをインストールしますか？
"""

スキルをインストールした後は、ユーザーに「新しいスキルを反映させるために Codex を再起動してください」と伝えてください。

## スクリプト

これらのスクリプトはすべてネットワークを使用するため、サンドボックスで実行する場合は実行時にエスカレーションをリクエストしてください。

- `scripts/list-curated-skills.py`（インストール済みの注釈付きで厳選リストを表示）
- `scripts/list-curated-skills.py --format json`
- `scripts/install-skill-from-github.py --repo <owner>/<repo> --path <path/to/skill> [<path/to/skill> ...]`
- `scripts/install-skill-from-github.py --url https://github.com/<owner>/<repo>/tree/<ref>/<path>`

## 動作とオプション

- 公開 GitHub リポジトリの場合は、デフォルトで直接ダウンロードします。
- 認証/権限エラーでダウンロードが失敗した場合は、git sparse checkout にフォールバックします。
- 送信先のスキルディレクトリがすでに存在する場合は、処理を中止します。
- `$CODEX_HOME/skills/<skill-name>`（デフォルトは `~/.codex/skills`）にインストールします。
- 複数の `--path` 値を指定すると、1 回の実行で複数のスキルがインストールされます。`--name` が指定されない限り、各スキルはパスのベース名で命名されます。
- オプション：`--ref <ref>`（デフォルトは `main`）、`--dest <path>`、`--method auto|download|git`。

## 注意事項

- 厳選リストは GitHub API 経由で `https://github.com/openai/skills/tree/main/skills/.curated` から取得されます。利用できない場合は、エラーを説明して終了してください。
- プライベート GitHub リポジトリには、既存の git 資格情報、またはダウンロード用のオプションの `GITHUB_TOKEN`/`GH_TOKEN` を使用してアクセスできます。
- git へのフォールバックでは、最初に HTTPS、次に SSH を試行します。
- https://github.com/openai/skills/tree/main/skills/.system にあるスキルは事前インストールされているため、ユーザーのインストールを支援する必要はありません。尋ねられた場合は、その旨を説明してください。ユーザーが強く希望する場合は、ダウンロードして上書きすることができます。
- インストール済みの注釈は `$CODEX_HOME/skills` から取得されます。
