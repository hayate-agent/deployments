# syntax=docker/dockerfile:1
# Build context: a sibling checkout of https://github.com/hayate-agent/core.
ARG NODE_IMAGE=node:24.22.1-bookworm-slim@sha256:55fb5f5a527ea2c5c4a95f963e48ef90aa38c7b346054fdc8ee9957a2b55d205
FROM ${NODE_IMAGE} AS build
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci --include=dev --ignore-scripts \
    && npm rebuild @matrix-org/matrix-sdk-crypto-nodejs \
    && node -e 'require("@matrix-org/matrix-sdk-crypto-nodejs")'
COPY tsconfig.json plugins.lock.json ./
COPY scripts ./scripts
COPY src ./src
# Public Core ships the exact locked adapters for an offline materialization.
COPY vendor ./vendor
RUN npm run build && npm prune --omit=dev

FROM ${NODE_IMAGE}
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates git python3 ripgrep util-linux \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/hayate-agent
COPY --from=build /src/package.json ./
COPY --from=build /src/node_modules ./node_modules
COPY --from=build /src/dist ./dist
COPY docs ./docs
COPY LICENSE ./LICENSE
# Precreate writable state parents before nested read-only config mounts exist.
RUN mkdir -p /home/node/.hayate-agent /home/node/.pi/agent \
    && chown -R 1000:1000 /home/node
USER 1000:1000
ENV HOME=/home/node NODE_ENV=production
WORKDIR /workspace
ENTRYPOINT ["node", "/opt/hayate-agent/dist/cli.js"]
CMD ["run"]
