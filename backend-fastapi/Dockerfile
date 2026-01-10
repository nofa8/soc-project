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

# 1. Create a non-root user for security (SOC standard)
RUN useradd -m -u 1000 appuser

WORKDIR /app

# 2. Set environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

# 3. Copy the synchronized app from builder and set ownership to our new user
COPY --from=builder --chown=appuser:appuser /app /app

# 4. Create logs directory and ensure permissions are correct
# We give ownership to appuser and the root group (GID 0) for OpenShift/K8s compatibility
USER root

RUN mkdir -p /app/logs && \
    chown -R appuser:appuser /app/logs && \
    chmod -R 775 /app/logs

# 5. Switch to the non-root user
USER appuser

EXPOSE 8000

# 6. Run the app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
