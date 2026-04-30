# MCP 導入方針

このリポジトリでは、VS Code の MCP を「対話的な調査・検討・構築で、CLI 単体より文脈付きの操作価値が高いもの」に限定して導入する。

逆に、単発コマンドの実行やスクリプト化が中心で、既存 CLI が十分に強いものは MCP の対象外とする。

## 採用判断の基準

- MCP を使う: 認証済み API や外部サービスを横断しながら、探索的に調べる・設計する・構築する価値が高い
- MCP を使う: リソース参照、スキーマ参照、対話的な候補絞り込み、複数ステップの検討を Chat 上で進めたい
- CLI を優先する: 定型実行、CI/CD、シェルスクリプト化、自動化ジョブ、単発の状態確認が主目的
- CLI を優先する: すでに `gh`、`aws`、`terraform`、`kubectl` などで十分に運用でき、MCP の追加価値が薄い

## 情報取得パターン
## CLI を優先する理由

**実環境操作は CLI を基本とします。理由：**

### 1. Readonly がデフォルト

本番環境への変更はパイプライン経由（GitHub Actions など）に限定する運用を前提とします。

- AWS リソース操作：`aws` CLI は API 呼び出しが CloudTrail に記録される
- Terraform 操作：`terraform plan` / `apply` は CI/CD で実行し、すべてのコミットハッシュと一緒に履歴管理
- MCP を通した操作はこの原則と相性が悪い（Chat ログに分散、audit trail が不明確）

### 2. LLM コンテキスト効率

生成AI ツールのトークン消費を抑えるため：

- **CLI**: 単発コマンド＆出力で完結。スクリプト化すれば Chat 文脈に含める必要がない
- **MCP**: Chat で複数ステップの対話が発生。会話全体がコンテキストに入り、トークン消費が大きくなる
- **戦略**: 調査・検討は Chat で MCP 使用；実装・実行はスクリプト化して CI/CD に組み込む

### 3. 監査・再現性

すべての環境変更を Git と CI ログで完全に再現可能にする：

- CLI コマンド → GitHub Actions ログ → 誰が・何を・いつ・なぜ
- MCP 経由の操作 → Chat ログに分散 → 再現が困難

## 情報取得パターン

情報取得は用途で分ける。

- **ナレッジ**: ドキュメント、API リファレンス、スキーマ、ベストプラクティス、設定例など、静的で再利用可能な情報
- **実環境情報**:
  - **単発確認**: リソース一覧、現在のステータス、設定値確認 → CLI で十分
  - **対話的分析**: 複合条件検索、履歴調査、根因分析、複数サービス連携 → MCP で価値あり

### 対象別の対応状況

| サーバー | ナレッジ機能 | 単発確認（CLI） | 対話的分析（MCP） | 推奨運用 |
| -------- | ----------- | ------------|----------|----------|
| **AWS** | ✅ Knowledge MCP（docs/API/ベストプラクティス） | ✅ `aws` CLI | △ AWS Labs MCP（複数サービス連携、Cost Estimation） | ナレッジ MCP 導入；実環境は CLI 優先；複雑分析は MCP 検討 |
| **Terraform** | ✅ Providers/Modules Resources（スキーマ、リファレンス） | ✅ `terraform` / `hcp` CLI | ✅ Terraform MCP（HCP Terraform 履歴検索、根因分析） | ナレッジ + 対話的分析 MCP 両方導入；実環境確認は CLI |
| **New Relic** | ❌ 専用ナレッジ MCP なし | ✅ `newrelic nrql` CLI | ✅ New Relic MCP（対話的問い合わせ） | ナレッジ MCP 実装待ち；実環境は実装後に検討 |
| **GitHub** | ❌ ナレッジ MCP なし | ✅ `gh` CLI | △ GitHub MCP あり | `gh` CLI 優先；初期段階では MCP 不採用 |

## 初期対象

ナレッジ機能とナレッジ+対話的分析の 2 階層で採用。

| 分類 | MCP 導入 | 用途 | CLI での役割 |
| ---- | ------ | ------|----------|
| **AWS** | ✅ Knowledge MCP | 最新ドキュメント、API リファレンス、WAF ガイダンス、Well-Architected ガイダンス参照 | `aws` コマンド：リソース確認、状態操作（認証設定は [docs/cli-setup.md](cli-setup.md) 参照） |
| **Terraform** | ✅ Terraform MCP | ナレッジ：Providers/Modules スキーマ・リファレンス<br>対話的分析：HCP Terraform 実行履歴検索、失敗原因分析、Cost Estimation データ参照 | `terraform` / `hcp` コマンド：ローカル検証、plan、apply、state 管理（認証設定は [docs/cli-setup.md](cli-setup.md) 参照） |
| **New Relic** | 保留 | ナレッジ MCP 実装待ち；ナレッジ機能が揃ったら再評価 | 実環境メトリクス取得は `newrelic nrql` / CLI で対応 |
| **Kubernetes** | 次点 | `kubectl explain` で基本は足りる；MCP の追加価値を検証中 | `kubectl` / `helm`：基本運用 |

## CLI を優先するもの

以下は、少なくとも初期段階では MCP を導入しない。

| 対象 | CLI / 既存手段 | 判断理由 |
| ---- | -------------- | -------- |
| GitHub | `gh` | Issue / PR / Workflow / Release 操作が CLI で十分；MCP より `gh` を優先。ナレッジ機能も MCP にはなく、GitHub Docs / GraphQL Explorer での学習が標準的 |
| Playwright | `npx playwright`, `playwright test` | ブラウザ自動化や E2E は CLI とテストコードの方が再現性が高い |
| Docker / Compose | `docker`, `docker compose` | 定型操作が中心で、既存 CLI と相性がよい |
| Kubernetes の基本運用 | `kubectl`, `helm`, `k9s` | apply, logs, rollout, diff などは CLI の方が素直；`kubectl explain` でスキーマ確認も可能 |
| draw.io | VS Code 拡張 `hediet.vscode-drawio` | 図の編集が主で、MCP を入れるより拡張で十分 |

## 初期導入の考え方

- ユーザープロファイル用の `mcp.json` を dotfiles で配布する
- MCP は**ナレッジ機能**を中心に導入；実環境情報は CLI（`aws`、`terraform`、`hcp`）を優先
  - 単発確認（現在のリソース、ステータス）：CLI
  - 対話的分析（複合検索、根因分析、複数サービス連携）：MCP
- 秘密情報は `mcp.json` に直書きせず、環境変数や VS Code の input variables を使う
- 対話的な設計・学習で Chat 上での文脈参照が価値の高いものから導入

## CLI 環境の準備

MCP を使う場合も、実環境情報取得には CLI が必須です。認証設定方法は [docs/cli-setup.md](cli-setup.md) に記載。

- `aws` CLI：AWS Knowledge MCP と組み合わせて利用
- `terraform` / `hcp` CLI：Terraform MCP による対話的分析を補完

## 初期採用対象

実装予定順：

1. **AWS Knowledge MCP**
   - AWS ドキュメント、API リファレンス、WAF ガイダンス、最新 What's New
   - CLI：`aws` コマンドでリソース確認、操作

2. **Terraform MCP**
   - ナレッジ：Providers/Modules のスキーマ、リファレンス、ベストプラクティス
   - 対話的分析：HCP Terraform での実行履歴検索、失敗原因分析、Cost Estimation
   - CLI：`terraform`、`hcp` コマンドでローカル検証・デプロイ

## 将来検討候補

- **New Relic MCP**: 実環境情報（NRQL/Entity/Alert）での価値あり。ナレッジ機能の実装待ち
- **AWS Labs MCP（複数サービス）**: Knowledge MCP で基本は足りるが、複数サービス連携による自動分析の効果を検証してから拡大検討
- **Kubernetes**: `kubectl explain` と CLI 充実で基本は足りる；MCP の追加価値を検証中

段階的に導入し、運用実績に基づいて拡大を判断する。
## セットアップと実装

### 1. 前提条件

MCP サーバーは Node.js/npm または Brew でインストール可能です。

```bash
# 確認
node --version
npm --version
```

### 2. MCP サーバーのインストール

#### AWS Knowledge MCP

公式ドキュメント参照: https://knowledge-mcp.global.api.aws

**動作要件:**
- `uvx` コマンド（uv ツールのインストール必須）

**uv のインストール:**
```bash
brew install uv
```

**セットアップ完了時の実行:**

`.dotconfig/vscode/mcp.json` に以下の設定があれば、VS Code は自動的に `uvx fastmcp run https://knowledge-mcp.global.api.aws` でサーバーを起動します。追加インストール不要 - `uv` があれば自動的に必要なパッケージをダウンロード・実行します。

#### Terraform MCP Server

公式ドキュメント参照: https://github.com/hashicorp/terraform-mcp-server

**動作要件:**
- Docker（Terraform MCP Server のコンテナ実行用）

**セットアップ:**

Docker イメージは自動的に `docker run` で取得されます。事前にインストール作業は不要です。

### 3. mcp.json の設定

`.dotconfig/vscode/mcp.json` は dotfiles で管理・配布されます。

MCP サーバーは認証情報を必要としません。認証が必要な HCP Terraform 操作（run history 検索、apply 実行など）は、CLI コマンド（`terraform` / `hcp` CLI）に寄せてください（参照: [docs/cli-setup.md](cli-setup.md)）。

**macOS でのデプロイ:**

```bash
make deploy-vscode
```

このコマンドで `.dotconfig/vscode/mcp.json` が以下に配置されます:
```
~/Library/Application Support/Code/User/mcp.json
```

### 4. VS Code での確認

VS Code を再起動後、以下で MCP サーバーの状態を確認できます:

**Command Palette** で検索:
```
MCP: List Servers
```

表示されたサーバーの状態が ✅ になっていれば正常です。

**Chat で使用:**

```
AWS Knowledge について、EC2 のセキュリティグループベストプラクティスを教えてください
```

```
Terraform で過去7日間に失敗した実行を全て表示してください
```
