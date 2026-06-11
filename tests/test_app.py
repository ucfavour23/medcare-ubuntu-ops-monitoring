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
