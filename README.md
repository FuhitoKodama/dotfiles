# dotfiles

## セットアップ

### 前提条件 (macOS のみ)

`make all-in-one` は内部で Homebrew をインストールし、Homebrew は Xcode Command Line Tools (CLT) を要求する。新規 macOS ではまず対話シェルで以下を実行し、GUI インストーラを完了させてからセットアップに進む。

```sh
xcode-select --install
```

インストール済みかどうかは `xcode-select -p` で確認できる（パスが返れば OK）。CLT が未導入のまま `make all-in-one` を実行すると `init_homebrew.sh` が検知して案内メッセージを出し中断する。

### プロキシ設定

社内NWから実行する場合は、`$HOME/.zlocal` に proxy 設定を追加してからセットアップを実行する

### 一括実行

新しい macOS 環境でセットアップする場合は、以下の一括コマンドを実行する。

```
make all-in-one
```

このコマンドは `deploy` と `install` を正しい順序で実行する。

### Dev Container

このリポジトリをそのまま VS Code の Dev Container として開くこともできる。

- VS Code の "Dev Containers: Reopen in Container" を実行すると、Ubuntu ベースのコンテナがビルドされ、`postCreateCommand` で `make all-in-one` が実行される。
- コンテナ内では Linuxbrew (Homebrew on Linux) を利用して macOS と共通の Brewfile を流す。
- `Brewfile_dev_gui` / `Brewfile_applications` などのデスクトップアプリ系 Brewfile はインストールしない (`init_homebrew.sh` 内で macOS のときのみ実行)。
- VS Code の設定ファイル (`deploy_vscode.sh`) は macOS / Codespaces / Coder / Linux の各環境に応じたユーザー設定ディレクトリへ展開される。
- VS Code 拡張は `.dotconfig/vscode/extensions.txt` を正本として管理し、Dev Container では `.devcontainer/devcontainer.json` の `customizations.vscode.extensions`、ローカルでは `init_vscode_extensions.sh` から導入する。

### デプロイ

dotfiles のシンボリックリンクを対象ディレクトリに作成する。

```
make deploy-<application_name>
```

すべてのアプリケーションを一括で deploy する場合は `make deploy-all` を使う。

### インストール

アプリケーションのインストールや設定を行う。

```
make init-<application_name>
```

すべてのアプリケーションを一括で install する場合は `make init-all` を使う。

### VS Code 拡張

汎用的に使いやすい VS Code 拡張は `.dotconfig/vscode/extensions.txt` で管理する。

```sh
make init-vscode-extensions
```

`make all-in-one` / `make init-all` でも同じ一覧を使って自動インストールされる。拡張一覧を更新したら、必要に応じて `.devcontainer/devcontainer.json` の `customizations.vscode.extensions` も同じ内容に合わせる。

### VS Code MCP と CLI 環境

MCP は「対話的な調査・検討・構築で、CLI 単体より価値があるもの」に限定して導入する。さらに「ナレッジ機能」を基準に選定し、実環境情報は既存 CLI を優先する。

- **MCP 方針と採用対象**: [docs/mcp.md](docs/mcp.md)
- **CLI 認証設定ガイド**: [docs/cli-setup.md](docs/cli-setup.md)

**初期段階での採用予定:**
- AWS Knowledge MCP（ドキュメント、API リファレンス、ベストプラクティス参照）
  - 実環境情報は `aws` CLI で取得（認証設定は [docs/cli-setup.md](docs/cli-setup.md)）
- Terraform MCP（Providers/Modules スキーマ、リファレンス、HCP Terraform 履歴分析）
  - 実環境操作は `terraform` / `hcp` CLI で実行（認証設定は [docs/cli-setup.md](docs/cli-setup.md)）

**CLI 優先（MCP 不採用）:**
- GitHub: `gh` コマンドで十分
- Playwright: `npx playwright` / `playwright test` で十分
- draw.io: VS Code 拡張で十分
- Kubernetes: `kubectl` / `helm` 優先、MCP は後続検討
- New Relic: ナレッジ MCP 実装待ち

## ローカル設定

一部の dotfiles は、`$HOME` 配下のローカル設定ファイルを追加で読み込める。

| file               | purpose                                             |
| ------------------ | --------------------------------------------------- |
| `.zlocal`          | zsh のローカル設定                                  |
| `.gitconfig.local` | git の global config 本体（氏名、メール、credential helper など環境依存値）。`~/.zshenv` で `GIT_CONFIG_GLOBAL` として参照される。共通設定は冒頭の `[include] path = ~/.gitconfig` で取り込む |

### 推奨設定

`.zlocal`

```
# 任意: 社内プロキシ
export http_proxy="YOUR_PROXY"
export https_proxy="YOUR_PROXY"
export HTTP_PROXY="$http_proxy"
export HTTPS_PROXY="$https_proxy"
```

初回セットアップ時は example をコピーして作成する。

```sh
cp ~/.zlocal.example ~/.zlocal
```

`.gitconfig.local`

```
[include]
	path = ~/.gitconfig
[user]
	name = YOUR_NAME
	email = YOUR_EMAIL
[credential]
	helper = osxkeychain
```

`~/.zshenv` が `GIT_CONFIG_GLOBAL=~/.gitconfig.local` をエクスポートするので、git はこのファイルを global config として読む。`gh auth setup-git` や VS Code の `git config --global` による書き込みもすべてこのファイルに入り、dotfiles 管理下の `~/.gitconfig` は汚染されない。共通設定（alias、hooksPath、secrets パターン等）は冒頭の include で取り込む。

初回セットアップ時は `make deploy-home` が example から自動生成する。手動でコピーする場合は次のコマンドを使う。

```sh
cp ~/.gitconfig.local.example ~/.gitconfig.local
```

`user.name` / `user.email` と credential helper は後述の [GitHub 初期セットアップ](#github-初期セットアップ) で設定する。

## GitHub 初期セットアップ

`make all-in-one` は認証状態に依存しないため、GitHub 連携は **初回利用時に一度だけ手動** で行う。以下を上から順に実行する。

### 1. GitHub へログイン

```sh
gh auth login
```

### 2. credential helper を登録

```sh
make remote-setup-github-auth
```

内部で `gh auth setup-git` を実行し、`~/.gitconfig.local` に credential helper を書き込む（`GIT_CONFIG_GLOBAL` により dotfiles 管理下の `~/.gitconfig` には差分が出ない）。

### 3. user.name / user.email を反映

```sh
make init-git-identity
```

GitHub API から取得して `~/.gitconfig.local` に書き込む。`user` スコープが無い場合は `<id>+<login>@users.noreply.github.com` にフォールバックする。

公開アドレス（GitHub 登録の実メール）で push したい場合は、事前に `user` スコープを追加する。

```sh
gh auth refresh -h github.com -s user
make init-git-identity
```

### 4. 状態確認

```sh
make doctor
```

`[Git Configuration]` セクションがすべて `✓` ならセットアップ完了。

### 5. 常用リポジトリの一括取得 (任意)

`.dotconfig/ghq/repositories.txt` に `<host>/<owner>/<repo>` 形式で常用リポジトリを列挙しておくと、次のコマンドで `~/ghq` 配下に一括取得できる（既存は `ghq get -u` で update のみ）。

```sh
make ghq-clone
```

- 実行前に `gh auth login` 済みであること（private repo を含む場合）
- 失敗したリポジトリは最後にサマリ表示されて他は続行する
- `make all-in-one` には含まれないので、初回認証後に任意のタイミングで実行する

### 参考: pre-push フックの拒否条件

`~/.git-templates/git-secrets/hooks/pre-push` を `core.hooksPath` で全リポジトリから参照する。以下を満たさない push は拒否される。

- `gh auth login` 済みであること
- `git user.name` / `git user.email` が設定済みであること
- `git user.email` がログイン中 GitHub アカウントのメールと一致すること（または `noreply`）

フックが反映されない場合は `make deploy-home` を再実行して `~/.git-templates` の配置を更新する。

### 参考: `.dotconfig/vscode/settings.json` の差分抑制

VS Code が `.dotconfig/vscode/settings.json` に環境依存の値を書き込んでリポジトリ差分として現れることがある。ローカル運用では `skip-worktree` で表示を抑制する。

```sh
make remote-ignore-local-diff
```

設定を更新してコミットしたいときは抑制を解除する。

```sh
make remote-unignore-local-diff
```

互換のため、`make coder-*` と `make devcontainer-*` も利用できる。

## 手動で行う追加設定

一部のアプリはスクリプトだけではセットアップが完了しない。

### SF Mono Square

mac にフォントを追加する。

```
open "$(brew --prefix sfmono-square)/share/fonts"
```

[SF Mono Square](https://github.com/delphinus/homebrew-sfmono-square)
