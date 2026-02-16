FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install git + Node.js (WhatsApp bridge)
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg git && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get purge -y gnupg && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://github.com/HKUDS/nanobot.git .

# Install Python deps + build WhatsApp bridge
RUN uv pip install --system --no-cache-dir . && \
    cd bridge && npm install && npm run build && cd ..

# Setup config (non-interactive) + healthz server
RUN mkdir -p /root/.nanobot
COPY config.json /root/.nanobot/config.json
RUN chmod 600 /root/.nanobot/config.json

# Create minimal healthz server
RUN echo 'from http.server import HTTPServer, BaseHTTPRequestHandler\nimport socketserver\nclass HealthzHandler(BaseHTTPRequestHandler):\n    def do_GET(self):\n        self.send_response(200)\n        self.send_header("Content-type", "text/plain")\n        self.end_headers()\n        self.wfile.write(b"helloworld")\nwith HTTPServer(("0.0.0.0", 7860), HealthzHandler) as httpd:\n    httpd.serve_forever()' > healthz.py

EXPOSE 7860 18790
ENTRYPOINT ["sh", "-c", "python3 healthz.py & nanobot gateway"]
