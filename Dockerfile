FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install git, sudo, libmagic1, Node.js 22, and Chromium for Puppeteer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg git sudo openssh-client libmagic1 \
        chromium \
        fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libcups2 \
        libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 libxcomposite1 \
        libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 libu2f-udev libvulkan1 \
        xdg-utils wget && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get purge -y gnupg && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

WORKDIR /app

# DNS fix + start gateway
RUN echo '#!/bin/sh\necho "nameserver 8.8.8.8" > /etc/resolv.conf\necho "nameserver 1.1.1.1" >> /etc/resolv.conf\nexec nanobot gateway' > /entrypoint.sh && chmod +x /entrypoint.sh

# Clone latest nanobot
RUN git clone https://github.com/HKUDS/nanobot.git .

# SSH to HTTPS rewrite
RUN git config --global --add url."https://github.com/".insteadOf ssh://git@github.com/ && \
    git config --global --add url."https://github.com/".insteadOf git@github.com:

# Install Python deps + Telegram. WebUI builds automatically!
RUN uv pip install --system --no-cache-dir ".[telegram]"

# Pre-install MCP servers globally
RUN npm install -g \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-memory \
    @modelcontextprotocol/server-sequential-thinking \
    @modelcontextprotocol/server-puppeteer \
    tavily-mcp

# Copy config
RUN mkdir -p /root/.nanobot
COPY config.json /root/.nanobot/config.json
RUN chmod 600 /root/.nanobot/config.json

EXPOSE 7860 18790
ENTRYPOINT ["/entrypoint.sh"]
