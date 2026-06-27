# claude-statusline

A small, portable [statusline](https://docs.claude.com/en/docs/claude-code/statusline) for Claude Code.

It shows, in one line:

```
my-project  main*  opus 4.8  12% (50k/1000k) $0.42
```

- **directory** — basename of the current working directory (cyan)
- **git branch** — current branch, falls back to short commit hash on detached HEAD; a trailing `*` means uncommitted changes
- **model** — shortened display name (e.g. `opus 4.8`)
- **context %** — context window used, colored green/yellow/red at 50%/80%
- **tokens** — used / total context size in thousands
- **cost** — accumulated session cost in USD

## How it works

Claude Code pipes a JSON status blob into the script's stdin on every refresh.
The script parses it with `jq` and prints one line to stdout, which Claude Code
renders as the status bar.

## Requirements

- `bash`
- `jq`
- `awk`
- `git` (optional — branch info is just skipped outside a repo)

Honors the [`NO_COLOR`](https://no-color.org/) convention.

## Install

```bash
# 1. Save the script
curl -fsSL https://raw.githubusercontent.com/<you>/claude-statusline/main/claude-statusline.sh \
  -o ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/absolute/path/to/statusline.sh"
  }
}
```

Use an **absolute path** (`~` is not expanded). Restart Claude Code or reload
config for it to take effect.

## Test it without Claude Code

```bash
echo '{"model":{"display_name":"Opus 4.8"},"workspace":{"current_dir":"'"$PWD"'"},"context_window":{"used_percentage":12.5,"total_input_tokens":50000,"context_window_size":1000000},"cost":{"total_cost_usd":0.42}}' \
  | ./claude-statusline.sh
```

## License

MIT
