## 2026-02-20 | dotfiles | main | bootstrapping dotfiles repo
- Migrate hardcoded DD API keys/tokens in ~/.zshrc.work to macOS Keychain (use `security` like GITLAB_TOKEN)
- Add ~/.zshrc drift checker to work checkpoint — tools append to ~/.zshrc, need periodic cleanup to .zshrc.work
- Create ~/dotfiles/bin/ and add to PATH when personal scripts start accumulating
