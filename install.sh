#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude

ln -sf "$DOTFILES/.claude/CLAUDE.md" ~/.claude/CLAUDE.md

echo "Done. Symlinked ~/.claude/CLAUDE.md → $DOTFILES/.claude/CLAUDE.md"
