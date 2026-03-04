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

# Symlink tools
ln -sfn "$DOTFILES/tools" ~/tools

mkdir -p ~/.claude ~/.cursor

ln -sf "$DOTFILES/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sfn "$DOTFILES/.claude/skills" ~/.claude/skills
ln -sfn "$DOTFILES/.cursor/rules" ~/.cursor/rules

ln -sf "$DOTFILES/shell/zshrc" ~/.zshrc

mkdir -p ~/.config/karabiner
cp "$DOTFILES/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json

git config --global pull.rebase true

echo "Done. Symlinked:"
echo "  ~/tools → $DOTFILES/tools"
echo "  ~/.claude/CLAUDE.md → $DOTFILES/.claude/CLAUDE.md"
echo "  ~/.claude/skills/ → $DOTFILES/.claude/skills/"
echo "  ~/.cursor/rules/ → $DOTFILES/.cursor/rules/"
echo "  ~/.zshrc → $DOTFILES/shell/zshrc"
echo "  ~/.config/karabiner/karabiner.json ← $DOTFILES/karabiner/karabiner.json (copied, Karabiner breaks symlinks)"
