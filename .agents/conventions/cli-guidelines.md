# CLI Design Guidelines

Source: https://clig.dev/

Auto-consult when building or improving any CLI tool.

## Core Philosophy

Human-first design. Simple composable parts. Consistency across commands. Discoverable without sacrificing efficiency. Robust against misuse.

## Arguments & Flags

- Prefer flags over positional args – clearer, easier to extend
- Both short (`-h`) and long (`--help`) forms; one-letter flags only for common top-level options
- Standard names: `-q/--quiet`, `-v/--verbose`, `-f/--force`, `-n/--dry-run`, `--json`, `--no-input`, `-o/--output`
- Flags, args, subcommands should be order-independent where feasible
- Never read secrets from flags (visible in `ps`, shell history). Use `--password-file`, stdin, or credential stores
- Support `-` for stdin/stdout in file arguments

## Output

- Primary output → stdout. Messages/errors/progress → stderr
- Detect TTY: human-readable by default, machine-friendly when piped
- `--json` for structured output; `--plain` to disable formatting
- `--no-color` flag + respect `NO_COLOR` env var + `TERM=dumb`
- No animation/progress bars when stdout isn't a TTY
- Explain state changes – tell users what just happened
- Suggest next commands to guide workflows
- Make boundary-crossing actions explicit (network, writing files not passed as args)
- Use a pager (`less -FIRX`) for long output from interactive terminals

## Help

- `-h`/`--help` on every command and subcommand
- When invoked with no args and args are required: brief description, 1–2 examples, common flags, pointer to `--help`
- Lead with examples; put exhaustive examples in docs/web
- Display most common flags/commands first; group related items
- Suggest corrections on typos/mistakes

## Errors

- Catch expected errors; rewrite as human guidance, not stack traces
- Most important info at end of output (where users look)
- Group similar errors; minimize noise
- Unexpected errors: provide debug info + bug report instructions
- Pre-populate bug report URLs where possible

## Interactivity

- Only prompt if stdin is a TTY
- `--no-input` flag to skip all prompts (fail with usage if input required)
- Prompt for missing input interactively, but never require prompts – all input passable via flags/args
- Confirm dangerous actions proportional to severity:
  - Mild (single file delete): optional confirm
  - Moderate (directory delete, remote changes): prompt + offer `--dry-run`
  - Severe (bulk destructive): require explicit `--confirm="name"` or typed confirmation
- Ctrl-C must always work; exit immediately, skip long cleanup on repeat

## Subcommands

- Consistent naming: pick `noun verb` or `verb noun`, stick with it
- Reuse flag names and output formats across subcommands
- Avoid ambiguous names (update vs upgrade)
- Don't create catch-all subcommands or allow prefix abbreviations

## Robustness

- Validate input early; bail with clear errors
- Print something within 100ms – responsiveness > speed
- Show progress for anything > 1s (spinners, bars)
- Implement timeouts for network ops with configurable defaults
- Make failed operations resumable on re-run (crash-only design)
- Anticipate misuse: scripts wrapping your tool, multiple instances, bad connections, case-insensitive filesystems

## Configuration

- Precedence: flags > env vars > project config (`.env`) > user config > system config
- Follow XDG Base Directory Specification (`~/.config/<app>/`)
- Ask consent before modifying non-program config files
- Env vars: uppercase + underscores, single-line values
- Respect standard env vars: `NO_COLOR`, `DEBUG`, `EDITOR`, `HTTP_PROXY`, `PAGER`, `TMPDIR`
- Don't read secrets from env vars (leaks to child processes, `ps`, Docker inspect). Use credential files or secret services

## Exit Codes

- 0 = success, non-zero = failure
- Use distinct codes for distinct failure modes where useful

## Naming & Distribution

- Short, memorable, lowercase-with-dashes
- Single binary when possible
- Easy uninstall, prominently documented

## Future-Proofing

- Keep changes additive; warn before breaking changes
- Encourage `--json`/`--plain` for script stability
- Don't allow arbitrary subcommand abbreviations (blocks future command names)

## Analytics

- Never phone home without consent
- Prefer opt-in; if opt-out, announce prominently and make disabling trivial
