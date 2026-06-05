# Claude Code マルチエージェント運用ガイド

`claude agents` コマンドと `--worktree` フラグを組み合わせて、Claude Code を複数エージェントで自律稼働させるための運用メモ。バックグラウンドエージェントの管理は CLI 側に取り込まれたので、その公式機能を使う前提に揃える。

- 人間は **オーケストレータ 1 つ** とだけ対話する
- 実装作業は **バックグラウンドエージェント複数** に委譲し、各エージェントは独立した worktree で動く
- ツール許可は `--dangerously-skip-permissions` で無確認実行する（隔離環境前提）

> [!WARNING]
> `--dangerously-skip-permissions` はすべてのツール実行を無確認で許可する。devcontainer / VM など隔離環境でのみ使うこと。ホスト直で multi-agent を自走させない。

## 全体像

```
orchestrator: claude agents ビュー（人間が触る唯一のUI）
  └─ ビューから worker をバックグラウンド dispatch
       ├─ worker1  worktree: repo-worker1   branch worker1
       ├─ worker2  worktree: repo-worker2   branch worker2
       └─ worker3  worktree: repo-worker3   branch worker3
```

- `claude -w <name>` が新規ブランチ付きの worktree を切るので、ワーカー同士のファイル競合は基本起きない
- 同じブランチを 2 つの worktree でチェックアウトできない git の仕様が競合防止として効く
- 各ワーカーはバックグラウンドセッションとして常駐し、`claude agents` ビューから状態確認・指示送信を行う
- 最終マージはオーケストレータが PR 作成 / `git merge` で集約する

## `claude agents` の役割

`claude agents` は **dispatch されたバックグラウンドセッションをまとめて管理するビュー**。共通の設定（permission モード、モデル、effort、`--add-dir`、`--mcp-config`、`--settings`）をビューから配下のセッションに伝播させられる。`--json` を付ければ稼働中セッション一覧を JSON で取り出せるので、スクリプトからの監視や指示送信も楽になる。

```bash
claude agents --help
```

## オーケストレータ起動

オーケストレータは **エージェントビューを開いた状態のセッション** として起動する。配下のワーカーには「途中で停止しない」設定をデフォルトで継承させる。

```bash
claude agents \
  --dangerously-skip-permissions \
  --permission-mode bypassPermissions \
  --effort max
```

主要フラグの意図:

| フラグ                                | 効果                                                                  |
| ------------------------------------- | --------------------------------------------------------------------- |
| `--dangerously-skip-permissions`      | dispatch 先セッションでもパーミッション確認を一切出さない             |
| `--permission-mode bypassPermissions` | 上と同等。明示しておくと CLAUDE.md やプラグインからの上書きでも残る   |
| `--effort max`                        | 途中で打ち切られにくい高エフォートで稼働させる                        |
| `--model opus`                        | dispatch 先のデフォルトモデルを固定（必要に応じて）                   |
| `--add-dir <dir>`                     | リポジトリ外の参照先を許可                                            |
| `--mcp-config <file>`                 | dispatch 先にも同じ MCP サーバを適用                                  |

## ワーカーの dispatch

オーケストレータから各ワーカーを **worktree 付きのバックグラウンドセッション** として起動する。`--worktree <name>` を渡すと CLI 側が新規ブランチと worktree を作り、そのセッションだけがそこに張り付く。

```bash
# worker1 を新規 worktree（ブランチ worker1）で起動
claude --worktree worker1 \
       --name worker1 \
       --dangerously-skip-permissions \
       --effort max
```

| フラグ                  | 効果                                                                         |
| ----------------------- | ---------------------------------------------------------------------------- |
| `-w, --worktree <name>` | 指定名のブランチで新規 worktree を作成し、そのセッションを worktree 内で起動 |
| `-n, --name <name>`     | プロンプト・`/resume` ピッカー・`claude agents` ビューでの表示名を固定       |
| `--brief`               | エージェント側からユーザーへ通知する `SendUserMessage` ツールを有効化        |

ワーカーを 3 つ並列で立ち上げる例:

```bash
for w in worker1 worker2 worker3; do
  claude --worktree "$w" --name "$w" \
         --dangerously-skip-permissions --effort max &
done
```

各ワーカーは別ブランチ・別 worktree なので、同名ファイルを編集しても物理的に衝突しない。起動後は `claude agents` ビューに一覧として現れる。

## ワーカーの一覧 / 監視

オーケストレータ側からは `claude agents --json` で稼働中セッションを取り出して、状態確認や追加指示の宛先決定に使う。

```bash
claude agents --json --cwd "$(git rev-parse --show-toplevel)"
```

`--cwd` を付けると当該リポジトリ配下から起動したセッションだけに絞り込める。

## 途中停止を避けるためのフラグまとめ

| 目的                                       | フラグ                                |
| ------------------------------------------ | ------------------------------------- |
| パーミッション確認で止まらない             | `--dangerously-skip-permissions`      |
| 同上を明示モードで指定                     | `--permission-mode bypassPermissions` |
| 思考打ち切りを抑えて長尺タスクを走らせる   | `--effort max`（必要なら `xhigh`）    |
| dispatch 先にも同じ設定を伝播              | これらを `claude agents` 起動時に渡す |
| 過負荷時のフォールバック先を用意（`-p`）   | `--fallback-model <model>`            |

> [!NOTE]
> `--effort max` は API コストが上がる。長時間の自走を許す前に `--max-budget-usd` や `claude agents --json` での監視を併用する。

## オーケストレータへの運用指示

リポジトリ直下の `CLAUDE.md` などに、人間が orchestrator にだけ会話すれば回るようルールを書いておく。

```markdown
あなたはオーケストレータです。実装作業は自分では行わず、`claude agents` ビューから
dispatch したワーカーに委譲します。

- ワーカーは worker1 / worker2 / worker3（独立した worktree で稼働中）
- 新しいワーカーが必要なときは `claude --worktree <name> --name <name>
  --dangerously-skip-permissions --effort max` で起動する
- 稼働中ワーカーは `claude agents --json` で確認する
- 進捗は agents ビュー越しに追い、ユーザーには結果のサマリだけ返す
```

## worktree の管理

- 一覧確認: `git worktree list`
- 後始末: `git worktree remove <path>`
- ワーカーが触る領域が重なる場合は、担当ファイル/ディレクトリをオーケストレータが明示するか、PR ベースで main に集約する運用にする
- ブランチ名と `--worktree <name>` を揃えておくと `git worktree list` の見通しが良い

## 隔離環境の確認

`--dangerously-skip-permissions` を使う前に、最低限以下が満たされているか確認する。

- devcontainer / VM / Codespaces など、ホスト FS から分離されている
- 認証情報（クラウド資格情報、`gh` トークンなど）が必要最小限しかマウントされていない
- ネットワーク到達範囲が限定されている、または外部書き込みが起きても困らない

## 参考コマンド

- `claude agents`: バックグラウンドエージェントの管理ビュー
- `claude agents --json`: 稼働中セッション一覧を JSON で出力
- `claude -w, --worktree <name>`: 新規 worktree（ブランチ付き）でセッションを起動
- `claude --dangerously-skip-permissions`: 全ツール無確認実行
- `claude --permission-mode bypassPermissions`: 上と同等を明示モードで指定
- `claude --effort max`: 高エフォートで長尺タスクを走らせる
- `claude -p "<prompt>"`: ヘッドレス実行（非対話）
