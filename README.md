# Claude Code Sandbox Image

Custom Docker image for Claude Code sandbox with bun, Foundry, GitHub CLI, and Claude Code pre-installed.

## Build

```bash
docker build --no-cache --build-arg CLAUDE_CODE_VERSION=$(date +%s) --progress=plain -t custom-claude-sandbox .
```

The `CLAUDE_CODE_VERSION` build arg busts the cache to ensure the latest version of Claude Code is installed.
