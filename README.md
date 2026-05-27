# Agent Sandbox Image

Custom Docker image for sandboxed agent work with bun, Foundry, GitHub CLI,
Claude Code, and OpenCode pre-installed.

## Build

```bash
docker build --no-cache \
  --build-arg CLAUDE_CODE_VERSION=$(date +%s) \
  --build-arg OPENCODE_VERSION=$(date +%s) \
  --progress=plain \
  -t custom-claude-sandbox .
```

The version build args bust the cache to ensure the latest Claude Code and
OpenCode CLIs are installed.
