#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude

ln -sf "$DOTFILES/.claude/CLAUDE.md" ~/.claude/CLAUDE.md

ln -sf "$DOTFILES/shell/zshrc" ~/.zshrc

echo "Done. Symlinked:"
echo "  ~/.claude/CLAUDE.md → $DOTFILES/.claude/CLAUDE.md"
echo "  ~/.zshrc → $DOTFILES/shell/zshrc"
