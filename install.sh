#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Seed ~/.zprofile on macOS if missing (homebrew PATH must be set at login, not per-shell)
if [[ "$OSTYPE" == darwin* && ! -f ~/.zprofile && -x /opt/homebrew/bin/brew ]]; then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' > ~/.zprofile
  echo "Created ~/.zprofile (homebrew)"
fi

# Install fzf if missing
_install_fzf_binary() {
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
      echo "fzf $FZF_VERSION installed to ~/.local/bin/fzf"
    else
      echo "Warning: unsupported architecture $ARCH – install fzf manually"
    fi
  else
    echo "Warning: could not determine fzf version – install fzf manually"
  fi
}

if ! command -v fzf &> /dev/null; then
  echo "Installing fzf..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install fzf
  else
    _install_fzf_binary
  fi
fi

# Install tmux if missing
if ! command -v tmux &> /dev/null; then
  echo "Installing tmux..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install tmux
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y tmux 2>/dev/null || echo "Warning: could not install tmux – install manually"
  else
    echo "Warning: tmux not found – install manually"
  fi
fi

# Install rtk if missing
if ! command -v rtk &> /dev/null; then
  echo "Installing rtk..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install rtk-ai/tap/rtk
  else
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
  fi
fi

# Install Codex CLI if missing
if ! command -v codex &>/dev/null; then
  echo "Installing Codex CLI..."
  if [[ -w "$(npm config get prefix)/lib" ]]; then
    npm i -g @openai/codex || echo "Warning: codex install failed"
  else
    npm i -g --prefix ~/.local @openai/codex || echo "Warning: codex install failed"
  fi
fi

# Symlink tools
ln -sfn "$DOTFILES/tools" ~/tools

mkdir -p ~/.claude ~/.cursor ~/.agents ~/.agents/skills ~/.claude/skills

# Clean broken symlinks in dirs we manage with per-item symlinks
for d in ~/.agents/skills ~/.claude/skills; do
  find "$d" -maxdepth 1 -type l 2>/dev/null | while read -r link; do
    [[ -e "$link" ]] || rm -f "$link"
  done
done

# Shared source of truth
ln -sfn "$DOTFILES/.agents/conventions" ~/.agents/conventions
ln -sfn "$DOTFILES/.agents/docs" ~/.agents/docs
ln -sf "$DOTFILES/.agents/AGENTS.md" ~/.agents/AGENTS.md
mkdir -p ~/.gemini
ln -sf "$DOTFILES/.gemini/GEMINI.md" ~/.gemini/GEMINI.md
[[ -L ~/GEMINI.md ]] && rm -f ~/GEMINI.md

# Shared skill sync: rebuild ~/.agents/skills, then sync Claude/Cursor views from it.
ln -sfn "$DOTFILES/.claude/agents" ~/.claude/agents
ln -sf "$DOTFILES/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$DOTFILES/.claude/settings.json" ~/.claude/settings.json

# Cursor/Claude shared skill sync (Codex reads ~/.agents/skills/ directly)
DOTFILES="$DOTFILES" WORK_DOTFILES="${WORK_DOTFILES:-$HOME/dotfiles-work}" "$DOTFILES/tools/dotfiles" _refresh-skills
ln -sfn "$DOTFILES/.cursor/rules" ~/.cursor/rules

# Codex CLI defaults (keep auth/local trust state in ~/.codex/)
if command -v codex &> /dev/null; then
  "$DOTFILES/tools/dotfiles" _sync-codex || echo "Warning: could not sync Codex defaults"
fi

# RTK Claude Code hook (generates local hook script + RTK.md)
if command -v rtk &> /dev/null && [[ ! -f ~/.claude/hooks/rtk-rewrite.sh ]]; then
  if rtk init --global --auto-patch --hook-only; then
    echo "RTK hook initialized for Claude Code"
  else
    echo "Warning: could not initialize RTK hook"
  fi
fi

ln -sf "$DOTFILES/shell/zshrc" ~/.zshrc
ln -sf "$DOTFILES/shell/tmux.conf" ~/.tmux.conf

# Karabiner (macOS only)
if [[ "$OSTYPE" == darwin* ]]; then
  mkdir -p ~/.config/karabiner
  cp "$DOTFILES/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json
fi

# Seed local-only files (never synced via git)
# Migrate old docs → artifacts (one-time, pre-docs-tier)
# Skip if ~/.agents/docs is already a symlink (new docs tier from dotfiles repo)
if [[ ! -L ~/.agents/docs && -d ~/.agents/docs && ! -d ~/.agents/artifacts ]]; then
  mv ~/.agents/docs ~/.agents/artifacts
  echo "Migrated ~/.agents/docs → ~/.agents/artifacts"
elif [[ ! -L ~/.agents/docs && -d ~/.agents/docs && -d ~/.agents/artifacts ]]; then
  echo "Warning: both ~/.agents/docs and ~/.agents/artifacts exist; merge manually" >&2
fi
mkdir -p ~/.agents/artifacts ~/.agents/sessions ~/.agents/state
if [[ ! -f ~/.agents/INBOX.md ]]; then
  cat > ~/.agents/INBOX.md <<'EOF'
## Refined

## Inbox

## Resolved
EOF
  echo "Created ~/.agents/INBOX.md"
fi
[[ ! -f ~/.agents/wins.md ]] && touch ~/.agents/wins.md && echo "Created ~/.agents/wins.md"

# Managed git preferences (declarative; overrides DD-provisioned defaults for these keys)
ln -sf "$DOTFILES/git/config" ~/.gitconfig.dotfiles
if ! git config --global --get-all include.path 2>/dev/null | grep -qF '.gitconfig.dotfiles'; then
  git config --global --add include.path '~/.gitconfig.dotfiles'
fi

echo "Done. Run 'dotfiles doctor' to verify, 'dotfiles' to sync ongoing."
true
