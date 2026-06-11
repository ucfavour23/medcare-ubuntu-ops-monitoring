from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from flask import Flask, jsonify, render_template


BASE_DIR = Path(__file__).resolve().parent
DEFAULT_HEALTH_PATH = BASE_DIR / "data" / "sample-health.json"

app = Flask(__name__)


def health_data_path() -> Path:
    return Path(os.getenv("HEALTH_DATA_PATH", DEFAULT_HEALTH_PATH))


def load_health_data() -> dict[str, Any]:
    path = health_data_path()
    if not path.exists():
        return {
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "hostname": "pending-agent-data",
            "cpu_used_percent": 0,
            "memory_used_percent": 0,
            "disk_used_percent": 0,
            "load_average": "0.00,0.00,0.00",
            "services": {},
        }

    with path.open(encoding="utf-8") as file:
        return json.load(file)


def status_for(value: float, warning: float, critical: float) -> str:
    if value >= critical:
        return "critical"
    if value >= warning:
        return "warning"
    return "healthy"


def build_dashboard_model() -> dict[str, Any]:
    data = load_health_data()
    cpu = float(data.get("cpu_used_percent", 0))
    memory = float(data.get("memory_used_percent", 0))
    disk = float(data.get("disk_used_percent", 0))
    services = data.get("services", {})
    stopped_services = [name for name, state in services.items() if state != "running"]

    return {
        "hostname": data.get("hostname", "unknown"),
        "timestamp": data.get("timestamp", "unknown"),
        "load_average": data.get("load_average", "unknown"),
        "metrics": [
            {"name": "CPU", "value": cpu, "unit": "%", "status": status_for(cpu, 70, 85)},
            {"name": "Memory", "value": memory, "unit": "%", "status": status_for(memory, 75, 90)},
            {"name": "Disk", "value": disk, "unit": "%", "status": status_for(disk, 75, 90)},
        ],
        "services": services,
        "overall_status": "critical" if stopped_services else "healthy",
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
