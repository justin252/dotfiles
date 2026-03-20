# Shell Script Conventions

Auto-consult when writing or modifying shell scripts (bash/zsh).

## Strict Mode

- `set -euo pipefail` at top of every bash script
- `-e` (errexit): exit on first error. `-u` (nounset): unset vars are errors. `-o pipefail`: propagate pipeline failures
- Add `-E` (errtrace) if using ERR traps – ensures functions/subshells inherit them
- Gotchas: `-u` breaks when sourcing external files that use unset vars – wrap with `set +u; source file; set -u`. `pipefail` breaks `cmd | grep pattern || default` – use `PIPESTATUS` array or disable locally
- `pipefail` is bash-only (not POSIX sh/dash) – errors if script runs as `sh`

## Error Handling

- `trap cleanup EXIT` for temp files, background processes – runs on both success and error
- ERR trap for debugging: `trap 'echo "FAIL: $BASH_COMMAND at line $LINENO" >&2' ERR`
- Temp files: always `mktemp` (never hardcoded `/tmp/myfile`), always trap-cleaned

## Quoting

- ALWAYS quote variable expansions: `"$var"`, `"$(cmd)"`, `"${arr[@]}"`
- Unquoted = deliberate word splitting/globbing (rare, comment why)
- `"${arr[@]}"` expands each element as a separate word (preserves spaces)
- Command substitution: `$(cmd)` not backticks – easier nesting, clearer escaping

## Common Pitfalls

- Never parse `ls` output – use globs (`for f in *.txt`) or `find -print0` + `while IFS= read -r -d ''`
- `[ ]` is a command (`test`); `[[ ]]` is bash syntax – prefer `[[ ]]` in bash for safer string/regex ops
- Subshell variable scope: changes in `(...)`, pipelines (`cmd | while`), and `$(...)` don't propagate to parent
- Function syntax: `foo() { ... }` (POSIX) – not `function foo() { ... }` (mixed syntax)
- `for x in $(cmd)` splits on whitespace – use `while IFS= read -r line` for line-by-line
- Unquoted globs expand: `var=*` assigns matching filenames, not the literal `*`

### `set -e` traps

- `2>/dev/null` on fallible commands hides the cause of death – rescue errors inside the command or don't suppress stderr
- `[[ cond ]] && action` exits the script when condition is false (returns 1). Use `if [[ cond ]]; then action; fi` or append `|| true`. Safe inside loops/if bodies; dangerous at top level or in function bodies.
- `trap ... RETURN` referencing local vars crashes under `set -u` – locals are destroyed before the trap fires. Use EXIT trap (script-level) or explicit cleanup.
- `${arr[@]:-}` on an empty array produces one empty string, not zero iterations. Before destructive ops: `[[ ${#arr[@]} -gt 0 ]] || return`

## Cross-Platform

- Linux support is required, not optional
- BSD (macOS) vs GNU known traps:
  - `find -perm +mode` (BSD) vs `-perm /mode` (GNU) – use `[[ -x file ]]` instead
  - `find -exec test -e {} \; -delete` (BSD) – use a loop
  - `wc` output has leading spaces on BSD – pipe through `tr -d ' '`
  - `pbcopy`/`open` (macOS-only) – guard with `command -v`, provide `xclip`/`xdg-open` fallback
- Prefer existence checks (`command -v`, `[[ -d ]]`) over OS checks (`$OSTYPE`)
- Only guard with `$OSTYPE` when genuinely platform-specific
- `local` is only valid inside functions – bash enforces this; zsh is permissive. Don't use at top level

## Security

- No `eval` – use arrays, functions, or proper parsing instead
- No SUID/SGID on shell scripts – too many security holes
- Never read secrets from flags (visible in `ps`, shell history) or env vars (leak to children)
- Use `--password-file`, stdin, or credential stores for secrets
- Validate external input – quote and sanitize before use

## Install/Repair Flows

- Design for clean machine first – create dirs before scanning them
- Optional integrations: warn and continue, don't abort the full install
- Only delete clearly managed paths; if a path might contain user content, prefer symlink-only removal or warn
- Smoke-test with a temp `HOME`: `HOME="$(mktemp -d)" bash install.sh`

## Shell Startup

- Never source commands that hit the network in `.zshrc`/`.bashrc`
- Auth/token refreshes → on-demand wrapper or lazy evaluation
- Keep startup fast: defer expensive operations behind functions

## Testing

- ShellCheck: `shellcheck script.sh` – catches most common errors statically
- Syntax check: `bash -n file` / `zsh -n file`
- Double-source: `zsh -c 'source ~/.zshrc; source ~/.zshrc'` – catches alias conflicts, duplicate path entries
- Clean-machine: `HOME="$(mktemp -d)" bash install.sh` – verifies no implicit dependencies
