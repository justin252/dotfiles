# Claude Code Modes

Four workflows:

| Command | What it does |
|---------|-------------|
| `cc` | Coding session. All tools auto-allowed, pauses at checkpoints. |
| `cc` + "teach" | Same, but narrates every change – how it fits the plan, gotchas, idioms. |
| `ccplan` | Read-only research. Can't edit files or run commands. |
| `ccy` + `/yolo <plan>` | Full autonomy. Implements plan → tests → commits → draft PRs. No prompts. |

`/yolo` only works from `ccy`. Running it from `cc` still hits permission prompts – use `ccy` for autonomous work.

---

## Execute (`cc`) – default

| Alias | What |
|-------|------|
| `cc` | New session |
| `ccc` | Continue last session |
| `ccr` | Resume (pick session) |
| `ccp` | Pipe/print (non-interactive) |
| `ccw` | Watch mode |
| `ccadd ~/code/a ~/code/b` | Continue + extra repos |

All tools auto-allowed via `settings.json` dontAsk. No prompts for reads, edits, bash, agents, MCP.

Say **"teach"** anytime for narrated diffs – explains how each change fits the plan, links to code, approves each logical unit.

## Plan (`ccplan`) – read-only

| Alias | What |
|-------|------|
| `ccplan` | Interactive plan session |
| `ccplanc` | Continue last plan session |
| `ccplanadd ~/code/a ~/code/b` | Plan + extra repos |

For exploring, designing, researching. Cannot edit files or run arbitrary commands.

## Yolo (`ccy` → `/yolo`) – full autonomy

| Alias | What |
|-------|------|
| `ccy` | New session, skip all permissions |
| `cccy` | Continue, skip all permissions |
| `ccry` | Resume, skip all permissions |
| `ccbot` | Pipe mode, skip all permissions |
| `ccpipe` | Pipe + stream-json output |

**Typical workflow:**
```
$ ccy                                          # start yolo session
> /yolo ~/.claude/plans/saved/retry-logic.md   # kick off autonomous loop
> /yolo #42                                    # ...or from an issue
> /yolo "add retry logic with exponential backoff"  # ...or inline
```

**Single task?** Just `ccy` + describe what you want. No `/yolo` needed.

**Multi-task plan?** `ccy` → `/yolo <plan>`. The skill reads the plan, checks existing draft PRs for progress, then loops: branch → implement → test → commit → draft PR. Resumable – run `/yolo` on the same plan again and it picks up where it left off.

Safety: permission checks skipped, behavioral confirmation gates overridden. Hard safety rules still apply (never force-push main, never rm -rf ~/, never delete unmerged branches).

## Skills

| Command | What it does |
|---------|-------------|
| `/checkpoint` | The only release path: build, test, commit, push, PR |
| `/yolo <plan>` | Autonomous loop (use from `ccy` only) |
| `/retro` | Capture friction/learnings to INBOX.md |
| `openplan` | Opens most recent plan in Cursor |
