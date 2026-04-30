.PHONY: all-in-one deploy-all deploy-home deploy-vscode init-all init-brew init-node init-custom-pure init-ghq init-vscode-extensions init-git-identity ghq-clone doctor remote-setup-github-auth remote-ignore-local-diff remote-unignore-local-diff coder-setup-github-auth coder-ignore-local-diff coder-unignore-local-diff devcontainer-setup-github-auth devcontainer-ignore-local-diff devcontainer-unignore-local-diff

all-in-one: deploy-home init-all deploy-all

deploy-all:
	@$(foreach val, $(wildcard ./setup/deploy/deploy_*.sh), bash $(val);)

deploy-home:
	bash ./setup/deploy/deploy_home.sh

deploy-vscode:
	bash ./setup/deploy/deploy_vscode.sh

init-all:
	@$(foreach val, $(wildcard ./setup/init/*.sh), bash $(val);)

init-brew:
	bash ./setup/init/init_homebrew.sh

init-node:
	bash ./setup/init/init_node.sh

init-custom-pure:
	bash ./setup/init/init_custom_pure.sh

init-ghq:
	bash ./setup/init/init_ghq.sh

init-vscode-extensions:
	bash ./setup/init/init_vscode_extensions.sh

doctor:
	bash ./setup/doctor.sh

# gh auth login 後に手動実行する。GitHub API から user.name / user.email を取得し ~/.gitconfig.local に書き込む
init-git-identity:
	bash ./setup/manual/init_git_identity.sh

# gh auth login 後に手動実行する。.dotconfig/ghq/repositories.txt に列挙したリポジトリを ghq get -u で一括取得する
ghq-clone:
	bash ./setup/manual/init_ghq_clone.sh

# Coder/Dev Container等のリモート環境で gh auth setup-git 等のローカル変更による差分を抑制する
remote-setup-github-auth:
	gh auth status -h github.com
	gh auth setup-git

remote-ignore-local-diff:
	git update-index --skip-worktree .dotconfig/vscode/settings.json

remote-unignore-local-diff:
	git update-index --no-skip-worktree .dotconfig/vscode/settings.json

# Backward-compatible aliases
coder-setup-github-auth: remote-setup-github-auth

coder-ignore-local-diff: remote-ignore-local-diff

coder-unignore-local-diff: remote-unignore-local-diff

devcontainer-setup-github-auth: remote-setup-github-auth

devcontainer-ignore-local-diff: remote-ignore-local-diff

devcontainer-unignore-local-diff: remote-unignore-local-diff
