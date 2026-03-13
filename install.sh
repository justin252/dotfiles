#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Install fzf if missing
if ! command -v fzf &> /dev/null; then
  echo "Installing fzf..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install fzf
  elif command -v apt-get &> /dev/null && apt-get install -y fzf 2>/dev/null; then
    echo "fzf installed via apt-get"
  else
    # Binary download fallback (works without sudo, behind proxies)
    echo "Downloading fzf binary from GitHub..."
    FZF_VERSION=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
    if [[ -n "$FZF_VERSION" ]]; then
      ARCH=$(uname -m)
      case "$ARCH" in
        x86_64)  FZF_ARCH="linux_amd64" ;;
        aarch64) FZF_ARCH="linux_arm64" ;;
        *)       FZF_ARCH="" ;;
      esac
      if [[ -n "$FZF_ARCH" ]]; then
        mkdir -p "$HOME/.local/bin"
        curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-${FZF_ARCH}.tar.gz" | tar xz -C "$HOME/.local/bin"
        echo "fzf installed to ~/.local/bin/fzf (ensure ~/.local/bin is on PATH)"
      else
        echo "Warning: unsupported architecture $ARCH – install fzf manually"
      fi
    else
      echo "Warning: could not determine fzf version – install fzf manually"
    fi
  fi
fi

# Symlink tools
ln -sfn "$DOTFILES/tools" ~/tools

mkdir -p ~/.claude ~/.cursor ~/.agents

# Shared source of truth
# Skills use per-skill symlinks (real dir) so work dotfiles can add work-only skills
[[ -L ~/.agents/skills ]] && rm ~/.agents/skills
mkdir -p ~/.agents/skills
for skill in "$DOTFILES/.agents/skills"/*/; do
  ln -sfn "$skill" ~/.agents/skills/"$(basename "$skill")"
done
ln -sfn "$DOTFILES/.agents/references" ~/.agents/references
ln -sf "$DOTFILES/.agents/AGENTS.md" ~/.agents/AGENTS.md

# Claude Code discovery (skills -> merged dir, not personal dir)
[[ -L ~/.claude/skills ]] && rm ~/.claude/skills
ln -sfn ~/.agents/skills ~/.claude/skills
ln -sfn "$DOTFILES/.claude/agents" ~/.claude/agents
ln -sf "$DOTFILES/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$DOTFILES/.claude/settings.json" ~/.claude/settings.json

# Cursor discovery
[[ -L ~/.cursor/skills ]] && rm ~/.cursor/skills
ln -sfn ~/.agents/skills ~/.cursor/skills

ln -sf "$DOTFILES/shell/zshrc" ~/.zshrc

# Karabiner (macOS only)
if [[ "$OSTYPE" == darwin* ]]; then
  mkdir -p ~/.config/karabiner
  cp "$DOTFILES/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json
fi

# Seed local-only files (never synced via git)
mkdir -p ~/documents
if [[ ! -f ~/.agents/INBOX.md ]]; then
  cat > ~/.agents/INBOX.md <<'EOF'
## Refined

## Inbox

## Resolved
EOF
  echo "Created ~/.agents/INBOX.md"
fi
[[ ! -f ~/.agents/wins.md ]] && touch ~/.agents/wins.md && echo "Created ~/.agents/wins.md"

git config --global pull.rebase true

echo "Done. Symlinked:"
echo "  ~/tools → $DOTFILES/tools"
echo "  ~/.agents/AGENTS.md → $DOTFILES/.agents/AGENTS.md"
echo "  ~/.agents/skills/*/ → $DOTFILES/.agents/skills/*/ (per-skill, mergeable)"
echo "  ~/.agents/references/ → $DOTFILES/.agents/references/"
echo "  ~/.claude/CLAUDE.md → $DOTFILES/.claude/CLAUDE.md"
echo "  ~/.claude/settings.json → $DOTFILES/.claude/settings.json"
echo "  ~/.claude/agents/ → $DOTFILES/.claude/agents/"
echo "  ~/.claude/skills/ → ~/.agents/skills/ (merged)"
echo "  ~/.cursor/skills/ → ~/.agents/skills/ (merged)"
echo "  ~/.zshrc → $DOTFILES/shell/zshrc"
[[ "$OSTYPE" == darwin* ]] && echo "  ~/.config/karabiner/karabiner.json ← $DOTFILES/karabiner/karabiner.json (copied, Karabiner breaks symlinks)"
