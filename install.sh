#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Install fzf if missing
if ! command -v fzf &> /dev/null; then
  echo "Installing fzf..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install fzf
  elif command -v apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y fzf
  else
    echo "Warning: fzf not found, install manually"
  fi
fi

# Clone tools repo if missing
if [[ ! -d "$HOME/tools" ]]; then
  echo "Cloning tools repo..."
  git clone git@github.com:justin252/tools.git "$HOME/tools"
else
  echo "Updating tools repo..."
  git -C "$HOME/tools" pull --rebase --autostash
fi

mkdir -p ~/.claude

ln -sf "$DOTFILES/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sfn "$DOTFILES/.claude/commands" ~/.claude/commands

ln -sf "$DOTFILES/shell/zshrc" ~/.zshrc

mkdir -p ~/.config/karabiner
cp "$DOTFILES/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json

git config --global pull.rebase true

echo "Done. Symlinked:"
echo "  ~/.claude/CLAUDE.md → $DOTFILES/.claude/CLAUDE.md"
echo "  ~/.claude/commands/ → $DOTFILES/.claude/commands/"
echo "  ~/.zshrc → $DOTFILES/shell/zshrc"
echo "  ~/.config/karabiner/karabiner.json ← $DOTFILES/karabiner/karabiner.json (copied, Karabiner breaks symlinks)"
