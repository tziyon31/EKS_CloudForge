#!/usr/bin/env python3
"""
EKS CloudForge Flask Application
A lightweight, cost-optimized Flask app designed for t3.micro instances
"""
import os
import platform
import time


from datetime import datetime

import psutil
from flask import Flask, Response, jsonify, render_template_string

# Initialize Flask application
app = Flask(__name__)

# Application configuration
app.config["JSON_SORT_KEYS"] = False  # Keep JSON order consistent

# Global variables for monitoring
START_TIME = datetime.now()
REQUEST_COUNT = 0

# HTML template for the main page
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EKS CloudForge - DevOps Pipeline Demo</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            padding: 30px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .status-card {
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            padding: 20px;
            text-align: center;
        }
        .status-card h3 {
            margin: 0 0 10px 0;
            font-size: 1.2em;
        }
        .status-card p {
            margin: 0;
            font-size: 1.1em;
            font-weight: bold;
        }
        .tech-stack {
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .tech-stack h2 {
            margin-top: 0;
            text-align: center;
        }
        .tech-list {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        .tech-item {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            padding: 15px;
            text-align: center;
        }
        .endpoints {
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            padding: 20px;
        }
        .endpoints h2 {
            margin-top: 0;
            text-align: center;
        }
        .endpoint-list {
            list-style: none;
            padding: 0;
        }
        .endpoint-list li {
            background: rgba(255, 255, 255, 0.1);
            margin: 10px 0;
            padding: 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
        }
        .uptime {
            font-size: 0.9em;
            text-align: center;
            margin-top: 20px;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 EKS CloudForge</h1>
        <p style="text-align: center; font-size: 1.2em; margin-bottom: 30px;">
            Complete DevOps Pipeline Demo - Running on Cost-Optimized t3.micro Instances
        </p>

        <div class="status-grid">
            <div class="status-card">
                <h3>Status</h3>
                <p style="color: #4ade80;">🟢 Healthy</p>
            </div>
            <div class="status-card">
                <h3>Instance Type</h3>
                <p>t3.micro</p>
            </div>
            <div class="status-card">
                <h3>Requests</h3>
                <p>{{ request_count }}</p>
            </div>
            <div class="status-card">
                <h3>Uptime</h3>
                <p>{{ uptime }}</p>
            </div>
        </div>

        <div class="tech-stack">
            <h2>🛠️ Technology Stack</h2>
            <div class="tech-list">
                <div class="tech-item">
                    <h4>AWS EKS</h4>
                    <p>Kubernetes Cluster</p>
                </div>
                <div class="tech-item">
                    <h4>Terraform</h4>
                    <p>Infrastructure as Code</p>
                </div>
                <div class="tech-item">
                    <h4>Docker</h4>
                    <p>Containerization</p>
                </div>
                <div class="tech-item">
                    <h4>Helm</h4>
                    <p>Kubernetes Package Manager</p>
                </div>
                <div class="tech-item">
                    <h4>GitHub Actions</h4>
                    <p>CI/CD Pipeline</p>
                </div>
                <div class="tech-item">
                    <h4>Flask</h4>
                    <p>Python Web Framework</p>
                </div>
            </div>
        </div>

        <div class="endpoints">
            <h2>🔗 Available Endpoints</h2>
            <ul class="endpoint-list">
                <li><strong>GET /</strong> - This page (main application)</li>
                <li><strong>GET /health</strong> - Health check endpoint</li>
                <li><strong>GET /status</strong> - Detailed application status</li>
                <li><strong>GET /metrics</strong> - System metrics and resource usage</li>
                <li><strong>GET /prometheus</strong> - Prometheus metrics (for monitoring)</li>
                <li><strong>GET /api/info</strong> - API information</li>
            </ul>
        </div>

        <div class="uptime">
            <p>🕐 Started: {{ start_time }}</p>
            <p>💻 Host: {{ hostname }}</p>
        </div>
    </div>
</body>
</html>
"""


@app.route("/")
def index():
    """Main application page with status and information."""
    global REQUEST_COUNT
    REQUEST_COUNT += 1

    # Calculate uptime
    uptime = datetime.now() - START_TIME
    uptime_str = str(uptime).split(".")[0]  # Remove microseconds

    return render_template_string(
        HTML_TEMPLATE,
        request_count=REQUEST_COUNT,
        uptime=uptime_str,
        start_time=START_TIME.strftime("%Y-%m-%d %H:%M:%S"),
        hostname=platform.node(),
    )


@app.route("/health")
def health():
    """Health check endpoint for load balancers and monitoring."""
    global REQUEST_COUNT
    REQUEST_COUNT += 1

    return (
        jsonify(
            {
                "status": "healthy",
                "timestamp": datetime.now().isoformat(),
                "uptime": str(datetime.now() - START_TIME).split(".")[0],
                "requests_processed": REQUEST_COUNT,
            }
        ),
        200,
    )


@app.route("/status")
def status():
    """Detailed application status and system information."""
    global REQUEST_COUNT
    REQUEST_COUNT += 1

    # Get system information
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage("/")

    return (
        jsonify(
            {
                "application": {
                    "name": "EKS CloudForge",
                    "version": "1.0.0",
                    "status": "running",
                    "start_time": START_TIME.isoformat(),
                    "uptime": str(datetime.now() - START_TIME).split(".")[0],
                    "requests_processed": REQUEST_COUNT,
                },
                "system": {
                    "hostname": platform.node(),
                    "platform": platform.platform(),
                    "python_version": platform.python_version(),
                    "cpu_count": psutil.cpu_count(),
                    "cpu_percent": cpu_percent,
                    "memory_total_gb": round(memory.total / (1024**3), 2),
                    "memory_available_gb": round(memory.available / (1024**3), 2),
                    "memory_percent": memory.percent,
                    "disk_total_gb": round(disk.total / (1024**3), 2),
                    "disk_free_gb": round(disk.free / (1024**3), 2),
                    "disk_percent": round((disk.used / disk.total) * 100, 2),
                },
                "environment": {
                    "instance_type": "t3.micro",
                    "region": os.environ.get("AWS_REGION", "unknown"),
                    "cluster_name": os.environ.get("EKS_CLUSTER_NAME", "unknown"),
                    "pod_name": os.environ.get("POD_NAME", "unknown"),
                    "namespace": os.environ.get("POD_NAMESPACE", "unknown"),
                },
            }
        ),
        200,
    )


@app.route("/metrics")
def metrics():
    """System metrics for monitoring and alerting."""
    global REQUEST_COUNT
    REQUEST_COUNT += 1

    # Get detailed metrics
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage("/")

    # Calculate request rate (requests per minute)
    uptime_minutes = (datetime.now() - START_TIME).total_seconds() / 60
    request_rate = REQUEST_COUNT / uptime_minutes if uptime_minutes > 0 else 0

    return (
        jsonify(
            {
                "metrics": {
                    "cpu_usage_percent": cpu_percent,
                    "memory_usage_percent": memory.percent,
                    "memory_available_mb": round(memory.available / (1024**2), 2),
                    "disk_usage_percent": round((disk.used / disk.total) * 100, 2),
                    "disk_free_mb": round(disk.free / (1024**2), 2),
                    "requests_total": REQUEST_COUNT,
                    "requests_per_minute": round(request_rate, 2),
                    "uptime_seconds": (datetime.now() - START_TIME).total_seconds(),
                },
                "alerts": {
                    "cpu_high": cpu_percent > 80,
                    "memory_high": memory.percent > 80,
                    "disk_high": (disk.used / disk.total) * 100 > 80,
                },
            }
        ),
        200,
    )


@app.route("/prometheus")
def prometheus_metrics():
    """Prometheus-compatible metrics endpoint."""
    global REQUEST_COUNT
    REQUEST_COUNT += 1

    # Get system metrics
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage("/")

    # Calculate uptime
    uptime_seconds = (datetime.now() - START_TIME).total_seconds()

    # Build Prometheus metrics
    metrics = []

    # Application metrics
    metrics.append("# HELP app_requests_total Total number of requests")
    metrics.append("# TYPE app_requests_total counter")
    metrics.append(f"app_requests_total {REQUEST_COUNT}")

    metrics.append("# HELP app_uptime_seconds Application uptime in seconds")
    metrics.append("# TYPE app_uptime_seconds gauge")
    metrics.append(f"app_uptime_seconds {uptime_seconds}")

    # System metrics
    metrics.append("# HELP container_cpu_usage_seconds_total Total CPU usage in seconds")
    metrics.append("# TYPE container_cpu_usage_seconds_total counter")
    metrics.append(f'container_cpu_usage_seconds_total{{container="eks-cloudforge-app"}} {cpu_percent / 100}')

    metrics.append("# HELP container_memory_usage_bytes Memory usage in bytes")
    metrics.append("# TYPE container_memory_usage_bytes gauge")
    metrics.append(f'container_memory_usage_bytes{{container="eks-cloudforge-app"}} {memory.used}')

    metrics.append("# HELP container_fs_usage_bytes Filesystem usage in bytes")
    metrics.append("# TYPE container_fs_usage_bytes gauge")
    metrics.append(f'container_fs_usage_bytes{{container="eks-cloudforge-app"}} {disk.used}')

    metrics.append("# HELP container_fs_limit_bytes Filesystem limit in bytes")
    metrics.append("# TYPE container_fs_limit_bytes gauge")
    metrics.append(f'container_fs_limit_bytes{{container="eks-cloudforge-app"}} {disk.total}')

    # HTTP metrics (simulated for demo)
    metrics.append("# HELP http_requests_total Total HTTP requests")
    metrics.append("# TYPE http_requests_total counter")
    metrics.append(f'http_requests_total{{job="eks-cloudforge-app",status="200"}} {REQUEST_COUNT}')

    metrics.append("# HELP http_request_duration_seconds_sum Sum of HTTP request durations")
    metrics.append("# TYPE http_request_duration_seconds_sum counter")
    metrics.append(f'http_request_duration_seconds_sum{{job="eks-cloudforge-app"}} {REQUEST_COUNT * 0.1}')

    metrics.append("# HELP http_request_duration_seconds_count Count of HTTP requests")
    metrics.append("# TYPE http_request_duration_seconds_count counter")
    metrics.append(f'http_request_duration_seconds_count{{job="eks-cloudforge-app"}} {REQUEST_COUNT}')

    # Cost estimation metrics
    estimated_cost_per_hour = (cpu_percent / 100) * 0.0001  # Rough cost estimation
    metrics.append("# HELP app_cost_per_hour Estimated cost per hour")
    metrics.append("# TYPE app_cost_per_hour gauge")
    metrics.append(f'app_cost_per_hour{{job="eks-cloudforge-app"}} {estimated_cost_per_hour}')

    # Add timestamp
    metrics.append("# HELP app_metrics_timestamp Last metrics collection timestamp")
    metrics.append("# TYPE app_metrics_timestamp gauge")
    metrics.append(f"app_metrics_timestamp {int(time.time())}")

    return Response("\n".join(metrics), mimetype="text/plain")


@app.route("/api/info")
def api_info():
    """API information and documentation."""
    global REQUEST_COUNT
    REQUEST_COUNT += 1

    return (
        jsonify(
            {
                "api": {
                    "name": "EKS CloudForge API",
                    "version": "1.0.0",
                    "description": "Lightweight Flask API for DevOps pipeline demonstration",
                    "endpoints": {
                        "GET /": "Main application page",
                        "GET /health": "Health check endpoint",
                        "GET /status": "Detailed application status",
                        "GET /metrics": "System metrics (JSON)",
                        "GET /prometheus": "Prometheus metrics (text/plain)",
                        "GET /api/info": "API information (this endpoint)",
                    },
                },
                "deployment": {
                    "containerized": True,
                    "orchestrator": "Kubernetes (EKS)",
                    "instance_type": "t3.micro",
                    "cost_optimized": True,
                    "auto_scaling": True,
                },
            }
        ),
        200,
    )


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors gracefully."""
    global REQUEST_COUNT
    REQUEST_COUNT += 1

    return (
        jsonify(
            {
                "error": "Not Found",
                "message": "The requested endpoint does not exist",
                "available_endpoints": [
                    "/",
                    "/health",
                    "/status",
                    "/metrics",
                    "/prometheus",
                    "/api/info",
                ],
            }
        ),
        404,
    )


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors gracefully."""
    global REQUEST_COUNT
    REQUEST_COUNT += 1

    return (
        jsonify(
            {
                "error": "Internal Server Error",
                "message": "An unexpected error occurred",
                "timestamp": datetime.now().isoformat(),
            }
        ),
        500,
    )


if __name__ == "__main__":
    # Get port from environment variable or default to 5000
    port = int(os.environ.get("PORT", 5000))

    # Get host from environment variable or default to 0.0.0.0
    host = os.environ.get("HOST", "0.0.0.0")

    print("🚀 Starting EKS CloudForge Flask Application")
    print(f"📍 Host: {host}")
    print(f"🔌 Port: {port}")
    print("💻 Instance Type: t3.micro")
    print("💰 Cost Optimized: Yes")
    print("🔄 Auto Scaling: Enabled")
    print("📊 Monitoring: Prometheus metrics available at /prometheus")

    # Start the Flask application
    app.run(host=host, port=port, debug=False)

# Trigger pipeline - Helm chart configmap and helper functions fixed, ready for full CI/CD run
# Simplified configmap to use values.yaml data instead of complex template syntax
# Fixed YAML parsing issues in helpers.tpl
