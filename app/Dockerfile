# =============================================================================
# EKS CloudForge Flask Application Dockerfile
# =============================================================================
# Multi-stage build optimized for t3.micro instances
# Focus on minimal image size, security, and resource efficiency

# =============================================================================
# STAGE 1: Build Stage
# =============================================================================
# Use Python 3.11 slim image for smaller size and better performance
FROM python:3.11-slim as builder

# Set environment variables for build optimization
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies needed for building Python packages
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# =============================================================================
# STAGE 2: Production Stage
# =============================================================================
# Use Python 3.11 slim image for production
FROM python:3.11-slim as production

# Set environment variables for production
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    PORT=5000 \
    HOST=0.0.0.0

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install runtime dependencies only (minimal for security)
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Create application directory
WORKDIR /app

# Copy application code
COPY app.py .

# Set proper permissions
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 5000

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Default command to run the application
CMD ["python", "app.py"]

# =============================================================================
# BUILD OPTIMIZATION NOTES:
# =============================================================================
# - Multi-stage build reduces final image size by ~200MB
# - Python 3.11 slim base image (~40MB vs ~200MB for full Python)
# - Non-root user for security
# - Minimal runtime dependencies
# - Health check for Kubernetes liveness/readiness probes
# - Environment variables for configuration

# =============================================================================
# RESOURCE USAGE ESTIMATES:
# =============================================================================
# - Base image: ~40MB
# - Python dependencies: ~20MB
# - Application code: ~1MB
# - Total image size: ~61MB
# - Runtime memory: ~50-100MB
# - Available for t3.micro: ~400-600MB

# =============================================================================
# SECURITY FEATURES:
# =============================================================================
# - Non-root user execution
# - Minimal attack surface (few packages)
# - No unnecessary system tools
# - Regular base image updates
# - Health check for monitoring

# =============================================================================
# BUILD COMMANDS:
# =============================================================================
# Build image:
#   docker build -t eks-cloudforge-app .
#
# Run locally:
#   docker run -p 5000:5000 eks-cloudforge-app
#
# Push to ECR:
#   docker tag eks-cloudforge-app:latest <ECR_REPO_URL>:latest
#   docker push <ECR_REPO_URL>:latest 