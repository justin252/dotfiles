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

# Bootstrap: symlink tools first so dotfiles tool is available
ln -sfn "$DOTFILES/tools" ~/tools

# RTK Claude Code hook (one-time; generates local hook script + RTK.md)
if command -v rtk &> /dev/null && [[ ! -f ~/.claude/hooks/rtk-rewrite.sh ]]; then
  if rtk init --global --auto-patch --hook-only; then
    echo "RTK hook initialized for Claude Code"
  else
    echo "Warning: could not initialize RTK hook"
  fi
fi

# Persist paths so standalone `dotfiles` runs resolve correctly in all environments
export DOTFILES
export WORK_DOTFILES="${WORK_DOTFILES:-$HOME/dotfiles-work}"
mkdir -p ~/.config/dotfiles
cat > ~/.config/dotfiles/paths <<EOF
DOTFILES="$DOTFILES"
WORK_DOTFILES="$WORK_DOTFILES"
EOF

# Delegate all managed state (symlinks, skills, configs, hooks, dirs, seeds) to dotfiles tool
"$DOTFILES/tools/dotfiles"

echo "Done. Run 'dotfiles doctor' to verify, 'dotfiles' to sync ongoing."
