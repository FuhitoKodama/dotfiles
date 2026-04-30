# Keybind List

このファイルは、現在の dotfiles で設定している VSCode と zsh のショートカットを一覧化したものです。

参照元:
- .dotconfig/vscode/keybindings.json
- .dotconfig/zsh/rc/bindkey.zsh

## VSCode Keybind

| キー | 動作 | 条件 |
|---|---|---|
| shift+enter | ターミナルへ Enter を送信 | terminalFocus |
| ctrl+enter | ターミナルへフォーカス | 常時 |
| ctrl+enter | エディタへフォーカスを戻す | terminalFocus |
| ctrl+space | パネルを最大化 or 元に戻す | 常時 |
| ctrl+m ctrl+space | パネル位置を下から右へ移動 | panelPosition == bottom |
| ctrl+m ctrl+space | パネル位置を右から下へ移動 | panelPosition == right |
| ctrl+shift+\\ | 次のターミナルへ移動 | terminalFocus |
| ctrl+\\ | 分割ターミナル内で次ペインへ移動 | terminalFocus |
| ctrl+shift+f | 単語単位で右へカーソル移動 | textInputFocus |
| ctrl+shift+b | 単語単位で左へカーソル移動 | textInputFocus |
| ctrl+w | 左側の単語削除 | textInputFocus && !editorReadonly |
| ctrl+j ctrl+w | 右側の単語削除 | textInputFocus && !editorReadonly |
| ctrl+m ctrl+m | VSCodeウィンドウ切り替え | 常時 |
| ctrl+j ctrl+k | カーソルを15行上へ移動 | editorTextFocus |
| ctrl+j ctrl+j | カーソルを15行下へ移動 | editorTextFocus |
| cmd+shift+n | エクスプローラで新規ファイル作成 | 常時 |
| cmd+option(alt)+n | エクスプローラで新規フォルダ作成 | 常時 |
| shift+space | 補完候補を表示 | editorHasCompletionItemProvider && textInputFocus && !editorReadonly && !suggestWidgetVisible |

補足:
- cmd を使う設定が含まれています。Linux環境で使う場合は必要に応じて ctrl ベースへ変更してください。

## zsh Keybind

前提設定:
- bindkey -d: デフォルトにリセット
- bindkey -e: Emacs風キーバインドを有効化
- bindkey ^[[3~ delete-char: Deleteキーで1文字削除

| キーシーケンス | 動作 | 実行関数 |
|---|---|---|
| Ctrl+R | 履歴を絞り込み選択してコマンドバッファへ挿入 | fzf-history-selection |
| Ctrl+U | cdr履歴から移動先を選択して cd 実行 | fzf-cdr |
| Ctrl+G Ctrl+G | ghq 管理リポジトリを選択して cd 実行 | fzf-ghq |
| Ctrl+G Ctrl+F | ghq 管理リポジトリを選択して code 実行 | fzf-ghq-vscode |
| Ctrl+G Ctrl+H | GitHub を検索し選んだリポジトリをブラウザで開く | open-my-repos |
| Ctrl+G Ctrl+P | GitHub を検索し選んだリポジトリを ghq get | fzf-ghq-get |

補足:
- 上記 zsh ショートカットは ghq / fzf / gh に依存します。
- cdr 系ショートカットは cdr と chpwd_recent_dirs が利用可能な環境で有効です。
- Ctrl+G Ctrl+H / Ctrl+G Ctrl+P は gh auth login 済みであることが前提です。検索対象は自分 + 所属 org のリポジトリです。

## OS別差分

結論:
- zsh キーバインドは基本的に macOS / Linux 共通で利用可能
- VSCode キーバインドはほぼ共通だが、cmd 系の2つだけ macOS 寄り

### 差分あり（VSCode）

| キー | macOS | Linux |
|---|---|---|
| cmd+shift+n | そのまま利用可 | 非推奨（環境によっては反応しない） |
| cmd+option(alt)+n | そのまま利用可 | 非推奨（環境によっては反応しない） |

Linux では上記2つを ctrl ベースへ置き換えるのがおすすめです。

### 差分なし（VSCode）

以下は macOS / Linux 共通で使える想定です。

- shift+enter
- ctrl+enter
- ctrl+space
- ctrl+m ctrl+space
- ctrl+shift+\\
- ctrl+\\
- ctrl+shift+f
- ctrl+shift+b
- ctrl+w
- ctrl+j ctrl+w
- ctrl+m ctrl+m
- ctrl+j ctrl+k
- ctrl+j ctrl+j
- shift+space

### 差分なし（zsh）

以下は macOS / Linux 共通で使える想定です。

- Ctrl+R: 履歴検索
- Ctrl+U: cdr から移動先選択
- Ctrl+G Ctrl+G: ghq repo へ cd
- Ctrl+G Ctrl+F: ghq repo を code で開く
- Ctrl+G Ctrl+H: GitHub 検索 → ブラウザで開く
- Ctrl+G Ctrl+P: GitHub 検索 → ghq get で取得

補足:
- zsh 側は OS よりも依存コマンド有無の影響が大きいです。
- 必須: ghq, fzf
- 追加要件: cdr, chpwd_recent_dirs（Ctrl+U用）
- 追加要件: gh（Ctrl+G Ctrl+H / Ctrl+G Ctrl+P用。gh auth login 済みであること）

## OS別クイックガイド

### macOS

- 現在の keybindings.json をそのまま利用可能です。

### Linux

- cmd+shift+n と cmd+option(alt)+n は ctrl ベースに変更推奨です。
- 例:
	- cmd+shift+n -> ctrl+shift+n
	- cmd+option(alt)+n -> ctrl+alt+n

## 使い方メモ

1. VSCode のショートカット変更元: .dotconfig/vscode/keybindings.json
2. zsh のショートカット変更元: .dotconfig/zsh/rc/bindkey.zsh
3. zsh 変更後は新しいターミナルを開くか、設定を再読み込みして反映
