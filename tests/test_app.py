from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import app.app as app_module
from app.app import build_dashboard_model, status_for


def test_status_for_thresholds():
    assert status_for(20, 70, 85) == "healthy"
    assert status_for(72, 70, 85) == "warning"
    assert status_for(91, 70, 85) == "critical"


def test_dashboard_model_contains_metrics():
    model = build_dashboard_model()

    assert model["hostname"]
    assert len(model["metrics"]) == 3
    assert {"CPU", "Memory", "Disk"} == {metric["name"] for metric in model["metrics"]}


def test_dashboard_model_marks_metric_warnings(monkeypatch):
    monkeypatch.setattr(
        app_module,
        "load_health_data",
        lambda: {
            "hostname": "warning-host",
            "cpu_used_percent": 72,
            "memory_used_percent": 40,
            "disk_used_percent": 50,
            "services": {"ssh": "running"},
        },
    )

    model = build_dashboard_model()

    assert model["overall_status"] == "warning"
    assert model["metrics"][0]["status"] == "warning"


def test_dashboard_model_handles_invalid_health_data(monkeypatch):
    health_path = Path(__file__).parent / "fixtures" / "invalid-health.json"
    monkeypatch.setenv("HEALTH_DATA_PATH", str(health_path))

    model = build_dashboard_model()

    assert model["hostname"] == "pending-agent-data"
    assert model["overall_status"] == "healthy"


def test_dashboard_model_clamps_metric_bars(monkeypatch):
    monkeypatch.setattr(
        app_module,
        "load_health_data",
        lambda: {"cpu_used_percent": 150, "memory_used_percent": -10},
    )

    model = build_dashboard_model()
    bars = {metric["name"]: metric["bar_value"] for metric in model["metrics"]}

    assert bars["CPU"] == 100
    assert bars["Memory"] == 0
