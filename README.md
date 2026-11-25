# am.nix

Home Manager による個人環境設定。空の Linux / macOS に Nix を入れ、このリポジトリを適用する手順です。

## 前提

| 項目 | 内容 |
| --- | --- |
| ユーザー名 | `am`（固定） |
| ホーム | Linux: `/home/am` / macOS: `/Users/am` |
| ホスト名 | `athena` = `x86_64-linux` / `am` = `aarch64-darwin`（Apple Silicon） |

上記以外の CPU・ユーザー名では、先に `flake.nix` と `hosts/default.nix` を直す必要があります。

## 1. Nix の導入

Determinate Nix を使います（flakes が最初から有効）。

### macOS（Apple Silicon）

推奨はグラフィカルインストーラです。

1. [Determinate.pkg](https://install.determinate.systems/determinate-pkg/stable/Universal) をダウンロードして開く
2. 画面の指示どおりインストールする
3. **新しいターミナル**を開き、動作確認する

```bash
nix --version
```

`nix (Determinate Nix …)` と出れば成功です。

コマンドラインだけで入れる場合:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

終わったらターミナルを開き直してください。

### Linux（x86_64、systemd あり）

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

終わったら **ログアウト／再ログイン**するか、新しいシェルを開きます。

```bash
nix --version
```

systemd が無い環境だけ、次を使います（一般ユーザーでは使えず、root / sudo が必要になります）。

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install linux --init none
```

## 2. このリポジトリを取得

```bash
git clone https://github.com/amwo/p.git ~/Projects/p
cd ~/Projects/p
```

`git` がまだ無い場合は、先に OS のパッケージマネージャで入れるか、一時的に次で取得できます。

```bash
nix shell nixpkgs#git --command git clone https://github.com/amwo/p.git ~/Projects/p
cd ~/Projects/p
```

## 3. 設定の適用

リポジトリ直下で、環境に対応するホスト名を渡します。

| 環境 | コマンド |
| --- | --- |
| macOS（Apple Silicon） | `nix run . -- am` |
| Linux（x86_64） | `nix run . -- athena` |

初回は依存の取得・ビルドで時間がかかります。成功すると Home Manager がユーザー環境を切り替え、最後に `zsh` が起動します。

同じことは次でもできます。

```bash
# macOS
nix run home-manager -- switch --flake .#am

# Linux
nix run home-manager -- switch --flake .#athena
```

## 4. ログインシェルを zsh にする

適用後、Nix 管理の zsh を既定シェルにします。

```bash
ls -l ~/.nix-profile/bin/zsh
```

`/etc/shells` に未登録なら追加します。

```bash
grep -qxF "$HOME/.nix-profile/bin/zsh" /etc/shells \
  || echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
```

既定シェルを切り替えます。

```bash
chsh -s "$HOME/.nix-profile/bin/zsh"
```

新しいターミナル（または再ログイン）で確認します。

```bash
echo "$SHELL"
which zsh
```

## 5. 以降の更新

設定を変えたあと、または入力を更新したあとは、リポジトリ直下で再適用します。

```bash
cd ~/Projects/p
nix run . -- am      # macOS
# または
nix run . -- athena  # Linux
```

入力だけ更新する場合:

```bash
nix flake update
nix run . -- <ホスト名>
```

## トラブルシュート

| 症状 | 確認 |
| --- | --- |
| `nix: command not found` | インストール後にシェルを開き直していない |
| ビルドがホスト不一致で失敗する | `am` / `athena` の取り違え、または未対応アーキテクチャ |
| ホームやユーザーが違う | `hosts/default.nix` の `username` / `homeDirectory` |
| unfree パッケージで止まる | `hosts/default.nix` の `allowUnfreePredicate` に名前を足す |

## 参考

- [Determinate Nix インストール](https://manual.determinate.systems/installation/)
- [Home Manager（flakes）](https://nix-community.github.io/home-manager/index.xhtml#ch-nix-flakes)
