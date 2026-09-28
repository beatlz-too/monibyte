FROM node:24-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && npm install -g @openai/codex \
 && npm cache clean --force
USER node
WORKDIR /work
