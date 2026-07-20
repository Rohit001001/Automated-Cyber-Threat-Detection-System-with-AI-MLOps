# =============================================================================
# Network Security MLOps — Production Dockerfile
# =============================================================================
# Multi-stage build for smaller image size and better security.
# Runs as non-root user. No hardcoded credentials.
# =============================================================================

# --- Stage 1: Builder ---
FROM python:3.10-slim-buster AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Stage 2: Production ---
FROM python:3.10-slim-buster AS production

# Security: Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

WORKDIR /app

# Install only runtime system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY networksecurity/ ./networksecurity/
COPY data_schema/ ./data_schema/
COPY templates/ ./templates/
COPY final_model/ ./final_model/
COPY app.py main.py push_data.py streamlit.py start.sh setup.py requirements.txt ./

# Set environment variables (non-sensitive defaults only)
ENV PYTHONPATH="/app:${PYTHONPATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Health check for container orchestrators
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Fix permissions
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose the FastAPI port
EXPOSE 8080

# Default command: run the FastAPI application
CMD ["python3", "app.py"]
