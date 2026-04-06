# ============================================================
# RalvClaw - 基于 OpenClaw 的中文版构建
# ============================================================
# 构建命令:
#   docker build -t ralvclaw:latest .
#
# 运行命令:
#   docker run -d --name ralvclaw -p 18789:18789 ralvclaw:latest
# ============================================================

# ============================================================
# 阶段 1: 构建阶段
# ============================================================
FROM node:24-bookworm-slim AS builder

# 安装构建依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    python3 \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 安装 Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# 启用 pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /build

# 下载最新 OpenClaw 上游源码
RUN curl -L -o openclaw.zip https://github.com/openclaw/openclaw/archive/refs/heads/main.zip && \
    unzip openclaw.zip && \
    mv openclaw-main openclaw && \
    rm openclaw.zip

# 复制 RalvClaw 汉化项目代码
COPY . ./ralvclaw/

WORKDIR /build/openclaw

# 应用汉化补丁
RUN node /build/ralvclaw/cli/apply.mjs --target=/build/openclaw --verbose || true

# 安装依赖
RUN pnpm install --frozen-lockfile || pnpm install --no-frozen-lockfile

# 构建
RUN pnpm canvas:a2ui:bundle || true
RUN pnpm build:docker || (node scripts/tsdown-build.mjs && node scripts/runtime-postbuild.mjs)
RUN pnpm ui:build

# 剪枝开发依赖
RUN pnpm prune --prod && \
    find dist -type f \( -name '*.d.ts' -o -name '*.d.mts' -o -name '*.d.cts' -o -name '*.map' \) -delete

# 更新包信息
RUN jq '.name = "ralvclaw"' package.json > tmp.json && mv tmp.json package.json && \
    jq '.description = "RalvClaw - 基于 OpenClaw 的中文版个人 AI 助手"' package.json > tmp.json && mv tmp.json package.json

# ============================================================
# 阶段 2: 运行时阶段
# ============================================================
FROM node:24-bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/1186258278/OpenClawChineseTranslation"
LABEL org.opencontainers.image.description="RalvClaw - 基于 OpenClaw 的中文版个人 AI 助手"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="RalvClaw"

# 设置环境变量
ENV NODE_ENV=production
ENV OPENCLAW_BUNDLED_PLUGINS_DIR=/app/extensions

# 安装运行时依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /app

# 从构建阶段复制产物
COPY --from=builder /build/openclaw/dist ./dist
COPY --from=builder /build/openclaw/node_modules ./node_modules
COPY --from=builder /build/openclaw/package.json .
COPY --from=builder /build/openclaw/openclaw.mjs .
COPY --from=builder /build/openclaw/extensions ./extensions
COPY --from=builder /build/openclaw/skills ./skills
COPY --from=builder /build/openclaw/docs ./docs

# 创建配置目录
RUN mkdir -p /root/.openclaw

# 暴露端口
EXPOSE 18789

# 数据持久化目录
VOLUME ["/root/.openclaw"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

# 默认启动命令
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
