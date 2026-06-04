"""Basic behavior tests for the MedCare monitoring dashboard."""

import unittest

from app import app


class DashboardTestCase(unittest.TestCase):
    """Verify the endpoints that operators and Docker depend on."""

    def setUp(self):
        app.config["TESTING"] = True
        self.client = app.test_client()

    def test_health_endpoint(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"status": "healthy"})

    def test_dashboard_renders(self):
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertIn(b"MedCare Ubuntu Operations", response.data)

    def test_metrics_api_returns_expected_fields(self):
        response = self.client.get("/api/metrics")
        payload = response.get_json()

        self.assertEqual(response.status_code, 200)
        self.assertIn("hostname", payload)
        self.assertIn("cpu_usage", payload)
        self.assertIn("memory_usage", payload)
        self.assertIn("disk_usage", payload)
        self.assertIn("services", payload)


if __name__ == "__main__":
    unittest.main()
