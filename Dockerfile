FROM docker/sandbox-templates:claude-code

# Install bun
ENV BUN_INSTALL="/home/agent/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"
RUN curl -fsSL https://bun.sh/install | bash && bun --version

# Install pnpm. Pin v10 because current sandbox base is Node 20, while pnpm
# 11 requires Node 22's node:sqlite module.
RUN npm install -g pnpm@10.33.4 && pnpm --version

# Install Foundry (forge, cast, anvil, chisel)
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/home/agent/.foundry/bin:$PATH"
RUN foundryup
RUN forge --version

# Install C toolchain (needed by Rust linker) + JDK 17 (for Scala/SBT)
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      g++ \
      pkg-config \
      libssl-dev \
      openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# Install SBT 1.9.8
RUN curl -fsSL "https://github.com/sbt/sbt/releases/download/v1.9.8/sbt-1.9.8.tgz" \
      | tar xz -C /usr/local --strip-components=1 \
    && sbt --version

# Fix ownership of /tmp/.sbt created by root during sbt --version above
RUN chown -R agent:agent /tmp/.sbt

USER agent

# Pre-warm SBT + Scala 2.13.12 caches so first project build doesn't download them
RUN mkdir -p /tmp/sbt-warmup/project /tmp/sbt-warmup/src/main/scala \
    && echo 'scalaVersion := "2.13.12"' > /tmp/sbt-warmup/build.sbt \
    && echo 'sbt.version=1.9.8' > /tmp/sbt-warmup/project/build.properties \
    && echo 'object Warmup' > /tmp/sbt-warmup/src/main/scala/Warmup.scala \
    && cd /tmp/sbt-warmup && sbt compile \
    && rm -rf /tmp/sbt-warmup

# Install Rust toolchain
ENV RUSTUP_HOME="/home/agent/.rustup"
ENV CARGO_HOME="/home/agent/.cargo"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
      --default-toolchain stable \
      --component rustfmt --component clippy
ENV PATH="/home/agent/.cargo/bin:$PATH"
RUN rustc --version && cargo --version && cargo fmt --version && cargo clippy --version

# Install GitHub CLI
RUN GH_VERSION=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+') \
  && GH_ARCH=$(dpkg --print-architecture) \
  && mkdir -p /home/agent/.gh-cli \
  && curl -fsSL "https://github.com/cli/cli/releases/latest/download/gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz" \
     | tar xz --strip-components=1 -C /home/agent/.gh-cli
ENV PATH="/home/agent/.gh-cli/bin:$PATH"
RUN gh --version

# Ensure PATH is available in runtime shells (sandbox may not inherit Docker ENV)
RUN echo 'export BUN_INSTALL="/home/agent/.bun"' >> /home/agent/.bashrc \
  && echo 'export RUSTUP_HOME="/home/agent/.rustup"' >> /home/agent/.bashrc \
  && echo 'export CARGO_HOME="/home/agent/.cargo"' >> /home/agent/.bashrc \
  && echo 'export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"' >> /home/agent/.bashrc \
  && echo 'export PATH="/home/agent/.cargo/bin:/home/agent/.bun/bin:/home/agent/.foundry/bin:/home/agent/.gh-cli/bin:$PATH"' >> /home/agent/.bashrc

# Install Claude Code (use CLAUDE_CODE_VERSION build-arg to bust cache)
ARG CLAUDE_CODE_VERSION=unknown
RUN npm install -g @anthropic-ai/claude-code@latest
RUN claude --version

# Install OpenCode (use OPENCODE_VERSION build-arg to bust cache)
ARG OPENCODE_VERSION=unknown
RUN npm install -g opencode-ai@latest
RUN opencode --version
