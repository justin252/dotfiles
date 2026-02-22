---
description: Analyze shell workflow and suggest tools, aliases, and cleanup
allowed-tools: Bash(read-only: history, brew list, which), Read, Write, Glob, Grep, WebSearch, WebFetch
---

Analyze the user's shell workflow and produce a structured improvement report.

## Steps

0. **Time window** — read `~/.claude/last-audit`. If it exists, parse the unix timestamp and only analyze history entries with timestamps after that value. If missing, analyze all history. History format is `: <timestamp>:0;<command>` (EXTENDED_HISTORY).

1. **History analysis** — read `~/.zsh_history`, filter entries by the time window from step 0, then frequency-count commands, find repeated multi-step sequences and long commands (30+ chars run 3+ times)

2. **Alias catalog** — read zshrc files (`~/dotfiles/shell/zshrc`, `~/.zshrc.work`, `~/.zshrc.personal` if they exist), catalog all aliases and functions

3. **Installed tools** — run `brew list --formula` to catalog what's installed

4. **Tool gap analysis** — cross-reference installed tools against known CLI ecosystem improvements:
   - File viewing: bat, eza, fd, tree
   - Data: jq, yq, xsv, csvkit
   - HTTP: httpie, curlie
   - Search: ripgrep, fzf, ag
   - Help: tldr, cheat
   - Git: delta, lazygit, gh
   - Misc: hyperfine, dust, duf, procs, bottom, zoxide
   - Search web for notable new CLI tools the user might not know about

5. **Alias candidates** — commands from history run 5+ times, 4+ chars, no existing alias

6. **Stale alias detection** — aliases defined in zshrc but never appearing in history

7. **Claude session optimization** — flag tools that'd make Claude Code sessions faster (better file viewers, search tools, formatters)

8. **Mark** — write current unix timestamp to `~/.claude/last-audit`

## Output format

```
## Audit window
<start date> → <end date> (<N> commands analyzed)

## Suggested installs
| Tool | Install | Why |
|------|---------|-----|

## Suggested aliases
| Alias | Command | Frequency |
|-------|---------|-----------|

## Suggested scripts (tools repo candidates)
- <name>: <what it does, why it's worth a script>

## Stale aliases
| Alias | Command | Notes |
|-------|---------|-------|

## Zshrc cleanup
- <opportunity>

## Claude session speedups
- <suggestion>
```

Be concrete. Don't suggest things already installed or aliased. Prioritize by impact.
