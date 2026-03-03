FROM docker/sandbox-templates:claude-code

# Install bun
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL="/home/agent/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"
RUN bun --version

# Install Foundry (forge, cast, anvil, chisel)
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/home/agent/.foundry/bin:$PATH"
RUN foundryup
RUN forge --version

# Install GitHub CLI
RUN mkdir -p /home/agent/.gh-cli \
  && curl -fsSL https://github.com/cli/cli/releases/latest/download/gh_$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')_linux_amd64.tar.gz | tar xz --strip-components=1 -C /home/agent/.gh-cli
ENV PATH="/home/agent/.gh-cli/bin:$PATH"
RUN gh --version

# Install Claude Code (use CLAUDE_CODE_VERSION build-arg to bust cache)
ARG CLAUDE_CODE_VERSION=unknown
RUN which claude && ls -la $(which claude) && npm list -g @anthropic-ai/claude-code 2>&1 || true
RUN npm uninstall -g @anthropic-ai/claude-code 2>/dev/null; rm -f $(which claude 2>/dev/null) 2>/dev/null; npm cache clean --force && npm install -g @anthropic-ai/claude-code@latest
RUN claude --version

