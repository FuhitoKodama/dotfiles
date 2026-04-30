# CLI 環境設定ガイド

MCP でナレッジ参照と対話的分析を行う場合も、実環境情報の取得と操作には CLI が必須です。

本ドキュメントは AWS CLI、Terraform CLI、HCP CLI、New Relic CLI の認証設定手順をまとめます。

## AWS CLI

### 認証方式

AWS CLI の認証には複数の方法がありますが、セキュリティと監査ログ の観点から以下の順で推奨します。

1. **IAM ロール（EC2 / ECS など実行環境）** ← 最推奨
2. **AWS SSO / SAML** ← チーム環境推奨
3. **IAM ユーザー + アクセスキー** ← ローカル開発環境

### セットアップ

#### 1. AWS CLI のインストール

```bash
# macOS（Homebrew）
brew install awscli

# または最新版を直接インストール
curl "https://awscli.amazonaws.com/awscli-exe-darwin-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### 2. 認証情報の設定

**方式 A: AWS SSO（推奨）**

```bash
aws sso configure

# 対話的に以下を入力:
# - SSO session name: my-sso-session
# - SSO start URL: https://your-org.awsapps.com/start
# - SSO region: us-east-1
# - Default region: ap-northeast-1
# - Default output format: json
```

生成される `~/.aws/config`:

```ini
[profile my-profile]
sso_session = my-sso-session
sso_account_id = 123456789012
sso_role_name = Developer

[sso-session my-sso-session]
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access
```

ログイン:

```bash
aws sso login --profile my-profile
```

**方式 B: IAM ユーザー + アクセスキー（ローカル開発）**

```bash
aws configure

# 対話的に入力:
# AWS Access Key ID: YOUR_ACCESS_KEY_ID
# AWS Secret Access Key: YOUR_SECRET_ACCESS_KEY
# Default region: ap-northeast-1
# Default output format: json
```

生成される `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

### 動作確認

```bash
# プロファイル確認
aws sts get-caller-identity --profile my-profile

# 出力例:
# {
#     "UserId": "AIDACKCEVSQ6C2EXAMPLE",
#     "Account": "<your-account-id>",
#     "Arn": "arn:aws:iam::<your-account-id>:user/myuser"
# }
```

### 環境変数での設定（オプション）

```bash
# ~/.zlocal または ~/.zprofile に追加
export AWS_REGION=ap-northeast-1
export AWS_OUTPUT=json
export AWS_PROFILE=my-profile  # SSO 使用時
```

### VS Code MCP での認証情報の参照

AWS Knowledge MCP と AWS Labs MCP は、以下の順序で認証情報を自動検出します。

1. `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` 環境変数
2. `~/.aws/credentials`
3. IAM ロール（実行環境）
4. AWS SSO ターゲットロール

---

## Terraform CLI / HCP CLI

Terraform を HCP Terraform（Terraform Cloud / Enterprise）と連携させる場合、2 つの CLI が必要です。

### Terraform CLI

#### インストール

```bash
# macOS（Homebrew）
brew install terraform

# または最新版を直接インストール
wget https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_darwin_amd64.zip
unzip terraform_1.9.0_darwin_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### 認証設定（HCP Terraform 連携）

**方式 A: `~/.terraform.rc` または `~/.terraformrc`**

```bash
credentials "app.terraform.io" {
  token = "YOUR_TFC_API_TOKEN"
}
```

**方式 B: 環境変数**

```bash
export TF_CLOUD_TOKEN=YOUR_TFC_API_TOKEN
export TF_CLOUD_HOSTNAME=app.terraform.io  # Terraform Cloud の場合
# 上記を ~/.zlocal に追加推奨
```

**方式 C: `credentials.tfrc.json`（新方式）**

```bash
mkdir -p ~/.terraform.d/credentials.tfrc.json

cat > ~/.terraform.d/credentials.tfrc.json << 'EOF'
{
  "credentials": {
    "app.terraform.io": {
      "token": "YOUR_TFC_API_TOKEN"
    }
  }
}
EOF

chmod 600 ~/.terraform.d/credentials.tfrc.json
```

#### API トークン取得

HCP Terraform / Terraform Cloud では、ユーザープロファイル→ API トークン より生成できます。

1. https://app.terraform.io/ にログイン
2. 左上アイコン → Settings → Tokens
3. Create an API token をクリック
4. トークンを `~/.terraform.rc` などにコピー

### HCP CLI（オプション）

HCP Terraform のワークスペース管理や詳細情報取得を CLI から行う場合に使用。

#### インストール

```bash
# Homebrew
brew install hashicorp/tap/hcp

# または公式サイトから
# https://www.hashicorp.com/products/hcp/cli
```

#### 認証設定

```bash
hcp auth login

# ブラウザが開き、コード入力を促されます
# コピー → 貼り付けで認証完了
```

認証情報の保存先:

```bash
~/.hcp/profile.json
```

#### 動作確認

```bash
hcp terraform workspace list --project-id=my-project
```

---

## New Relic CLI

New Relic のメトリクスやイベントを CLI で取得し、JSON 出力を LLM の入力として利用できます。

### インストール

```bash
# Homebrew
brew install newrelic-cli
```

### 認証設定

New Relic の User API Key を使って CLI プロファイルを作成します。

```bash
# 例: US リージョンの default プロファイル
newrelic profiles add \
  --profile default \
  --apiKey YOUR_NEW_RELIC_USER_KEY \
  -r us

# デフォルトプロファイル化
newrelic profiles default --profile default
```

リージョンは `us` または `eu` を指定します。

### 動作確認

```bash
newrelic version

# NRQL 実行（JSON 出力）
newrelic nrql query \
  --accountId YOUR_ACCOUNT_ID \
  --query "SELECT count(*) FROM Transaction SINCE 1 hour ago"
```

### LLM 用の情報取得（推奨）

LLM に渡す前提で、集計済みの小さな JSON を取得します。

```bash
# 例: 直近 30 分のエラー数
newrelic nrql query \
  --accountId YOUR_ACCOUNT_ID \
  --query "SELECT count(*) FROM TransactionError SINCE 30 minutes ago"

# 例: サービス別の平均応答時間（上位 10 件）
newrelic nrql query \
  --accountId YOUR_ACCOUNT_ID \
  --query "SELECT average(duration) FROM Transaction FACET appName SINCE 30 minutes ago LIMIT 10"
```

ポイント:

1. 生データ全件ではなく、NRQL で集約した結果を取得する
2. 期間を短めに指定し、トークン消費を抑える
3. `accountId` を明示して実行対象を固定する

### VS Code MCP での認証情報の参照

Terraform MCP は以下の順序で認証情報を自動検出します。

1. `TF_CLOUD_TOKEN` 環境変数
2. `~/.terraform.rc` または `~/.terraformrc`
3. `~/.terraform.d/credentials.tfrc.json`
4. `credentials.tfrc.json`（Terraform ワーキングディレクトリ）

### ローカル設定例（~/.zlocal）

```bash
# TFC / HCP Terraform の API トークン
export TF_CLOUD_TOKEN="<YOUR_TFC_API_TOKEN>"
export TF_CLOUD_HOSTNAME="app.terraform.io"

# オプション: HCP Terraform のワークスペース検索用環境変数
export HCP_CLIENT_ID="<YOUR_HCP_CLIENT_ID>"
export HCP_CLIENT_SECRET="<YOUR_HCP_CLIENT_SECRET>"
```

---

## 認証情報の安全な管理

### セキュリティベストプラクティス

1. **秘密情報をリポジトリに含めない**
   - `.aws/`、`~/.terraform.rc` はホームディレクトリのみ
   - dotfiles リポジトリには含めない（`.gitignore` 確認）

2. **認証情報のスコープを最小限に**
   - AWS IAM ロールで必要な権限のみ付与
   - TFC / HCP Terraform では組織内での権限を制限

3. **定期的なローテーション**
   - AWS アクセスキー：90 日ごと推奨
   - TFC / HCP API トークン：180 日ごと推奨

4. **環境別での分離**
   - 開発環境と本番環境で異なる認証情報を使用
   - AWS プロファイルで切り替え可能

### ~/.zlocal.example

初回セットアップ時の参考用テンプレート:

```bash
# AWS
export AWS_REGION=ap-northeast-1
export AWS_PROFILE=dev  # SSO プロファイル名

# Terraform Cloud / HCP Terraform
export TF_CLOUD_TOKEN="tfapi-XXXXXXXXXXXXXXXX"
export TF_CLOUD_HOSTNAME="app.terraform.io"

# New Relic CLI（任意: プロファイル方式を使わない場合）
# export NEW_RELIC_API_KEY="NRAK-XXXXXXXXXXXXXXXX"
# export NEW_RELIC_ACCOUNT_ID="1234567"
# export NEW_RELIC_REGION="us"

# 社内プロキシ（必要に応じて）
# export http_proxy="http://proxy.example.com:8080"
# export https_proxy="http://proxy.example.com:8080"
```

---

## トラブルシューティング

### AWS CLI

**エラー: "Unable to locate credentials"**

```bash
# 認証情報の確認
aws sts get-caller-identity

# 環境変数確認
echo $AWS_ACCESS_KEY_ID
echo $AWS_PROFILE

# プロファイル一覧
aws configure list-profiles
```

**エラー: "AccessDenied: User is not authorized"**

IAM ユーザー / ロールの権限を確認してください。MCP で実行する場合は、必要最小限の権限を付与してください。

### Terraform CLI

**エラー: "Failed to retrieve token from credentials"**

```bash
# トークンの有効性確認
terraform login -upgrade

# または環境変数の確認
echo $TF_CLOUD_TOKEN
cat ~/.terraform.rc
```

**エラー: "Cannot determine hostname"**

`TF_CLOUD_HOSTNAME` 環境変数が設定されていることを確認:

```bash
export TF_CLOUD_HOSTNAME="app.terraform.io"
# または
export TF_CLOUD_HOSTNAME="my-terraform-server.example.com"  # Terraform Enterprise
```

### HCP CLI

**エラー: "Not authenticated"**

```bash
# 認証情報の再生成
hcp auth login --force

# 認証情報の確認
cat ~/.hcp/profile.json
```

### New Relic CLI

**エラー: "authentication required"**

```bash
# プロファイル作成を再実行
newrelic profiles add --profile default --apiKey YOUR_NEW_RELIC_USER_KEY -r us
newrelic profiles default --profile default
```

**エラー: "missing accountId"**

```bash
# accountId を明示して実行
newrelic nrql query --accountId YOUR_ACCOUNT_ID --query "SELECT count(*) FROM Transaction SINCE 1 hour ago"
```

---

## 参考

- AWS CLI 公式ドキュメント: https://docs.aws.amazon.com/cli/latest/userguide/
- Terraform CLI ドキュメント: https://developer.hashicorp.com/terraform/cli
- HCP CLI ドキュメント: https://developer.hashicorp.com/hcp/docs/hcp-cli
- New Relic CLI ドキュメント: https://docs.newrelic.com/docs/new-relic-solutions/build-nr-ui/newrelic-cli/
