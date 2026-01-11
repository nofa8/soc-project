# --- Build Stage ---
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app

# Install dependencies using mounts for high speed
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

ADD . /app

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# --- Final Runtime Image ---
FROM python:3.13-slim-bookworm

# Create a non-root user for security (SOC standard)
RUN useradd -m -u 1000 appuser

WORKDIR /app

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

# Copy the synchronized app from builder and set ownership to our new user
COPY --from=builder --chown=appuser:appuser /app /app

# Install gosu
RUN apt-get update && \
    apt-get install -y gosu && \
    rm -rf /var/lib/apt/lists/*

# Copy entrypoint script. This script will create /app/logs and fix permissions at runtime
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Start as root to bind-mount permissions
USER root
# Set entrypoint to handle permissions and drop privileges
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Run the app
EXPOSE 8000
# Params passed to docker-entrypoint.sh
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
