# Terminal Text Editing

macOS text-editing muscle memory (Option/Cmd + arrows, Option/Cmd + Backspace) in terminal.

## Two layers

### 1. zsh bindkey (`shell/zshrc`)

Cross-platform; works even without oh-my-zsh (workspace fallback).

| Shortcut | Sequence | zsh widget |
|---|---|---|
| Option+Left | `^[b` | backward-word |
| Option+Right | `^[f` | forward-word |
| Cmd+Left | `^A` | beginning-of-line |
| Cmd+Right | `^E` | end-of-line |
| Option+Backspace | `^[^?` | backward-kill-word |
| Option+Delete | `^[d` | kill-word |
| Cmd+Backspace | `^U` | kill-whole-line |
| Cmd+Delete | `^K` | kill-line |

### 2. iTerm2 key mappings (macOS only)

iTerm2 must send the right escape sequences. Built-in preset handles this:

**Profiles > Keys > Key Mappings > Presets... > Natural Text Editing**

One click, maintained by iTerm2 devs. Covers all of the above plus edge cases.

What the preset maps:

| Shortcut | Sends | zsh binding |
|---|---|---|
| Opt+Left | `\eb` | backward-word |
| Opt+Right | `\ef` | forward-word |
| Cmd+Left | `0x01` (^A) | beginning-of-line |
| Cmd+Right | `0x05` (^E) | end-of-line |
| Opt+Backspace | `0x17` (^W) | backward-kill-word |
| Cmd+Backspace | `0x15` (^U) | kill-whole-line |
| Opt+Delete | `\ed` | kill-word |
| Cmd+Delete | `0x0b` (^K) | kill-line |

## Setup

1. `install.sh` symlinks `shell/zshrc` to `~/.zshrc` (bindkeys always active)
2. One-time in iTerm2: load Natural Text Editing preset

## Verification

```bash
source ~/.zshrc && bindkey | grep -E 'word|line'
```

Then test: Option+Left/Right jumps words, Cmd+Left/Right jumps to line edges, Option+Backspace deletes word backward.
