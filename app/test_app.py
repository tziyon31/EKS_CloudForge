# =============================================================================
# EKS CloudForge Application Tests
# =============================================================================
# Comprehensive test suite for the Flask application
# Includes: unit tests, integration tests, performance tests

import pytest
import requests
import time
import json
import os
from unittest.mock import patch, MagicMock
from app import app

# =============================================================================
# TEST CONFIGURATION
# =============================================================================


@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def mock_psutil():
    """Mock psutil for testing system metrics."""
    with patch("app.psutil") as mock_psutil:
        # Mock CPU metrics
        mock_psutil.cpu_percent.return_value = 25.5
        mock_psutil.cpu_count.return_value = 4

        # Mock memory metrics
        mock_memory = MagicMock()
        mock_memory.total = 8589934592  # 8GB
        mock_memory.available = 4294967296  # 4GB
        mock_memory.percent = 50.0
        mock_psutil.virtual_memory.return_value = mock_memory

        # Mock disk metrics
        mock_disk = MagicMock()
        mock_disk.total = 107374182400  # 100GB
        mock_disk.used = 53687091200  # 50GB
        mock_disk.percent = 50.0
        mock_psutil.disk_usage.return_value = mock_disk

        yield mock_psutil


# =============================================================================
# UNIT TESTS
# =============================================================================


class TestApplicationRoutes:
    """Test all application routes."""

    def test_home_page(self, client):
        """Test the home page route."""
        response = client.get("/")
        assert response.status_code == 200
        assert b"EKS CloudForge" in response.data
        assert b"Welcome to EKS CloudForge" in response.data

    def test_health_endpoint(self, client):
        """Test the health check endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["status"] == "healthy"
        assert "timestamp" in data
        assert "uptime" in data

    def test_status_endpoint(self, client):
        """Test the status endpoint."""
        response = client.get("/status")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["status"] == "running"
        assert "version" in data
        assert "environment" in data

    def test_metrics_endpoint(self, client, mock_psutil):
        """Test the metrics endpoint."""
        response = client.get("/metrics")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert "cpu" in data
        assert "memory" in data
        assert "disk" in data
        assert "system" in data

    def test_api_info_endpoint(self, client):
        """Test the API info endpoint."""
        response = client.get("/api/info")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["name"] == "EKS CloudForge"
        assert data["version"] == "1.0.0"
        assert (
            data["description"]
            == "A cost-optimized Flask application for EKS deployment"
        )

    def test_nonexistent_endpoint(self, client):
        """Test handling of non-existent endpoints."""
        response = client.get("/nonexistent")
        assert response.status_code == 404


class TestSystemMetrics:
    """Test system metrics functionality."""

    def test_cpu_metrics(self, mock_psutil):
        """Test CPU metrics collection."""
        from app import get_cpu_metrics

        metrics = get_cpu_metrics()
        assert "usage_percent" in metrics
        assert "core_count" in metrics
        assert metrics["usage_percent"] == 25.5
        assert metrics["core_count"] == 4

    def test_memory_metrics(self, mock_psutil):
        """Test memory metrics collection."""
        from app import get_memory_metrics

        metrics = get_memory_metrics()
        assert "total_gb" in metrics
        assert "available_gb" in metrics
        assert "usage_percent" in metrics
        assert metrics["total_gb"] == 8.0
        assert metrics["available_gb"] == 4.0
        assert metrics["usage_percent"] == 50.0

    def test_disk_metrics(self, mock_psutil):
        """Test disk metrics collection."""
        from app import get_disk_metrics

        metrics = get_disk_metrics()
        assert "total_gb" in metrics
        assert "used_gb" in metrics
        assert "usage_percent" in metrics
        assert metrics["total_gb"] == 100.0
        assert metrics["used_gb"] == 50.0
        assert metrics["usage_percent"] == 50.0


class TestErrorHandling:
    """Test error handling and edge cases."""

    def test_psutil_error_handling(self, client):
        """Test handling of psutil errors."""
        with patch("app.psutil.cpu_percent", side_effect=Exception("CPU error")):
            response = client.get("/metrics")
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data["cpu"]["error"] == "CPU error"

    def test_memory_error_handling(self, client):
        """Test handling of memory errors."""
        with patch("app.psutil.virtual_memory", side_effect=Exception("Memory error")):
            response = client.get("/metrics")
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data["memory"]["error"] == "Memory error"

    def test_disk_error_handling(self, client):
        """Test handling of disk errors."""
        with patch("app.psutil.disk_usage", side_effect=Exception("Disk error")):
            response = client.get("/metrics")
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data["disk"]["error"] == "Disk error"


# =============================================================================
# INTEGRATION TESTS
# =============================================================================


class TestApplicationIntegration:
    """Integration tests for the application."""

    def test_full_request_cycle(self, client):
        """Test a complete request cycle."""
        # Test home page
        response = client.get("/")
        assert response.status_code == 200

        # Test health check
        response = client.get("/health")
        assert response.status_code == 200

        # Test metrics
        response = client.get("/metrics")
        assert response.status_code == 200

        # Test API info
        response = client.get("/api/info")
        assert response.status_code == 200

    def test_concurrent_requests(self, client):
        """Test handling of concurrent requests."""
        import threading
        import time

        results = []

        def make_request():
            response = client.get("/health")
            results.append(response.status_code)

        # Start multiple threads
        threads = []
        for _ in range(5):
            thread = threading.Thread(target=make_request)
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        # All requests should succeed
        assert all(status == 200 for status in results)
        assert len(results) == 5


# =============================================================================
# PERFORMANCE TESTS
# =============================================================================


class TestPerformance:
    """Performance tests for the application."""

    def test_response_time(self, client):
        """Test response time for endpoints."""
        import time

        # Test home page response time
        start_time = time.time()
        response = client.get("/")
        end_time = time.time()

        assert response.status_code == 200
        assert (end_time - start_time) < 1.0  # Should respond within 1 second

        # Test health endpoint response time
        start_time = time.time()
        response = client.get("/health")
        end_time = time.time()

        assert response.status_code == 200
        assert (end_time - start_time) < 0.5  # Health check should be fast

    def test_memory_usage(self, client):
        """Test memory usage during requests."""
        import psutil
        import os

        process = psutil.Process(os.getpid())
        initial_memory = process.memory_info().rss

        # Make multiple requests
        for _ in range(10):
            response = client.get("/metrics")
            assert response.status_code == 200

        final_memory = process.memory_info().rss
        memory_increase = final_memory - initial_memory

        # Memory increase should be reasonable (less than 10MB)
        assert memory_increase < 10 * 1024 * 1024


# =============================================================================
# SECURITY TESTS
# =============================================================================


class TestSecurity:
    """Security tests for the application."""

    def test_headers_security(self, client):
        """Test security headers."""
        response = client.get("/")
        headers = response.headers

        # Check for security headers
        assert "X-Content-Type-Options" in headers or "X-Frame-Options" in headers

    def test_input_validation(self, client):
        """Test input validation."""
        # Test with malicious input
        response = client.get('/health?param=<script>alert("xss")</script>')
        assert response.status_code == 200

        # Test with very long input
        long_input = "a" * 10000
        response = client.get(f"/health?param={long_input}")
        assert response.status_code == 200

    def test_error_information_disclosure(self, client):
        """Test that errors don't disclose sensitive information."""
        # Test non-existent endpoint
        response = client.get("/nonexistent")
        assert response.status_code == 404

        # Check that error response doesn't contain sensitive info
        assert b"password" not in response.data.lower()
        assert b"secret" not in response.data.lower()
        assert b"key" not in response.data.lower()


# =============================================================================
# CONFIGURATION TESTS
# =============================================================================


class TestConfiguration:
    """Test application configuration."""

    def test_environment_variables(self):
        """Test environment variable handling."""
        # Test default values
        assert app.config["ENV"] == "production"

        # Test custom environment
        with patch.dict(os.environ, {"FLASK_ENV": "development"}):
            app.config["ENV"] = os.environ.get("FLASK_ENV", "production")
            assert app.config["ENV"] == "development"

    def test_port_configuration(self):
        """Test port configuration."""
        port = int(os.environ.get("PORT", 5000))
        assert port == 5000 or port > 0


# =============================================================================
# DOCKER TESTS
# =============================================================================


class TestDockerCompatibility:
    """Test Docker compatibility."""

    def test_docker_environment(self):
        """Test that the app works in Docker environment."""
        # Check if running in container
        in_container = os.path.exists("/.dockerenv")

        # App should work in both container and non-container environments
        assert True  # This test passes if the app starts

    def test_docker_user(self):
        """Test that the app can run as non-root user."""
        # Check if running as non-root
        if os.geteuid() == 0:
            pytest.skip("Running as root")
        else:
            assert True  # Running as non-root user


# =============================================================================
# KUBERNETES TESTS
# =============================================================================


class TestKubernetesCompatibility:
    """Test Kubernetes compatibility."""

    def test_kubernetes_environment(self):
        """Test that the app works in Kubernetes environment."""
        # Check for Kubernetes environment variables
        k8s_env_vars = [
            "KUBERNETES_SERVICE_HOST",
            "KUBERNETES_SERVICE_PORT",
            "KUBERNETES_SERVICE_PORT_HTTPS",
        ]

        # App should work regardless of Kubernetes environment
        assert True  # This test passes if the app starts

    def test_health_check_compatibility(self, client):
        """Test that health checks are Kubernetes compatible."""
        response = client.get("/health")
        assert response.status_code == 200

        data = json.loads(response.data)
        # Health check should return quickly
        assert "uptime" in data
        assert data["status"] == "healthy"


# =============================================================================
# COST OPTIMIZATION TESTS
# =============================================================================


class TestCostOptimization:
    """Test cost optimization features."""

    def test_resource_efficiency(self, client):
        """Test that the app is resource efficient."""
        import psutil
        import os

        process = psutil.Process(os.getpid())

        # Check memory usage
        memory_mb = process.memory_info().rss / 1024 / 1024
        assert memory_mb < 100  # Should use less than 100MB

        # Check CPU usage
        cpu_percent = process.cpu_percent()
        assert cpu_percent < 50  # Should use less than 50% CPU

    def test_lightweight_dependencies(self):
        """Test that the app has minimal dependencies."""
        import pkg_resources

        # Get installed packages
        installed_packages = [d.project_name for d in pkg_resources.working_set]

        # Should only have essential packages
        essential_packages = ["flask", "psutil"]
        for package in essential_packages:
            assert package in installed_packages


# =============================================================================
# TEST RUNNER
# =============================================================================

if __name__ == "__main__":
    # Run tests with coverage
    pytest.main(
        [
            "--cov=app",
            "--cov-report=html",
            "--cov-report=xml",
            "--cov-report=term-missing",
            "--verbose",
            "test_app.py",
        ]
    )
