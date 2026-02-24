#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude

ln -sf "$DOTFILES/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sfn "$DOTFILES/.claude/commands" ~/.claude/commands

ln -sf "$DOTFILES/shell/zshrc" ~/.zshrc

mkdir -p ~/.config/karabiner
ln -sf "$DOTFILES/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json

git config --global pull.rebase true

echo "Done. Symlinked:"
echo "  ~/.claude/CLAUDE.md → $DOTFILES/.claude/CLAUDE.md"
echo "  ~/.claude/commands/ → $DOTFILES/.claude/commands/"
echo "  ~/.zshrc → $DOTFILES/shell/zshrc"
echo "  ~/.config/karabiner/karabiner.json → $DOTFILES/karabiner/karabiner.json"
