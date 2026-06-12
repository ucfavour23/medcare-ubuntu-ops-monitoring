from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from flask import Flask, jsonify, render_template


BASE_DIR = Path(__file__).resolve().parent
DEFAULT_HEALTH_PATH = BASE_DIR / "data" / "sample-health.json"
DEFAULT_HEALTH_DATA: dict[str, Any] = {
    "timestamp": "pending-agent-data",
    "hostname": "pending-agent-data",
    "cpu_used_percent": 0,
    "memory_used_percent": 0,
    "disk_used_percent": 0,
    "load_average": "0.00,0.00,0.00",
    "services": {},
}

app = Flask(__name__)


def health_data_path() -> Path:
    return Path(os.getenv("HEALTH_DATA_PATH", DEFAULT_HEALTH_PATH))


def load_health_data() -> dict[str, Any]:
    path = health_data_path()
    if not path.exists():
        return DEFAULT_HEALTH_DATA | {
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        }

    try:
        with path.open(encoding="utf-8") as file:
            data = json.load(file)
    except (OSError, json.JSONDecodeError):
        return DEFAULT_HEALTH_DATA | {
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        }

    if not isinstance(data, dict):
        return DEFAULT_HEALTH_DATA

    return DEFAULT_HEALTH_DATA | data


def percent_value(value: Any) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def bar_value(value: float) -> float:
    return min(max(value, 0), 100)


def status_for(value: float, warning: float, critical: float) -> str:
    if value >= critical:
        return "critical"
    if value >= warning:
        return "warning"
    return "healthy"


def build_dashboard_model() -> dict[str, Any]:
    data = load_health_data()
    cpu = percent_value(data.get("cpu_used_percent"))
    memory = percent_value(data.get("memory_used_percent"))
    disk = percent_value(data.get("disk_used_percent"))
    services = data.get("services", {})
    if not isinstance(services, dict):
        services = {}
    stopped_services = [name for name, state in services.items() if state != "running"]
    metrics = [
        {
            "name": "CPU",
            "value": cpu,
            "bar_value": bar_value(cpu),
            "unit": "%",
            "status": status_for(cpu, 70, 85),
        },
        {
            "name": "Memory",
            "value": memory,
            "bar_value": bar_value(memory),
            "unit": "%",
            "status": status_for(memory, 75, 90),
        },
        {
            "name": "Disk",
            "value": disk,
            "bar_value": bar_value(disk),
            "unit": "%",
            "status": status_for(disk, 75, 90),
        },
    ]
    metric_statuses = {metric["status"] for metric in metrics}

    if stopped_services or "critical" in metric_statuses:
        overall_status = "critical"
    elif "warning" in metric_statuses:
        overall_status = "warning"
    else:
        overall_status = "healthy"

    return {
        "hostname": data.get("hostname", "unknown"),
        "timestamp": data.get("timestamp", "unknown"),
        "load_average": data.get("load_average", "unknown"),
        "metrics": metrics,
        "services": services,
        "overall_status": overall_status,
        "stopped_services": stopped_services,
    }


@app.get("/")
def dashboard():
    return render_template("dashboard.html", model=build_dashboard_model())


@app.get("/api/health")
def api_health():
    return jsonify(build_dashboard_model())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
