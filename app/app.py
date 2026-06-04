"""MedCare Ubuntu Operations & Monitoring Platform dashboard."""

import os
import platform
import socket
from datetime import datetime, timezone

import psutil
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)


def format_bytes(value):
    """Convert a byte value into a beginner-friendly display string."""
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(value)
    for unit in units:
        if size < 1024 or unit == units[-1]:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} TB"


def format_uptime(seconds):
    """Convert uptime seconds into days, hours, and minutes."""
    minutes = int(seconds // 60)
    days, minutes = divmod(minutes, 1440)
    hours, minutes = divmod(minutes, 60)
    return f"{days}d {hours}h {minutes}m"


def get_service_health():
    """Check whether configured process names are visible to the dashboard."""
    configured = os.getenv("MONITORED_SERVICES", "sshd,systemd").split(",")
    monitored_services = [name.strip() for name in configured if name.strip()]
    running_processes = set()

    for process in psutil.process_iter(["name"]):
        try:
            if process.info["name"]:
                running_processes.add(process.info["name"])
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    return [
        {"name": service, "status": "Healthy" if service in running_processes else "Not detected"}
        for service in monitored_services
    ]


def collect_metrics():
    """Collect the live server metrics used by the dashboard and API."""
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage("/")
    uptime_seconds = datetime.now(timezone.utc).timestamp() - psutil.boot_time()

    return {
        "hostname": socket.gethostname(),
        "current_time": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
        "cpu_usage": psutil.cpu_percent(interval=0.2),
        "memory_usage": memory.percent,
        "memory_detail": f"{format_bytes(memory.used)} / {format_bytes(memory.total)}",
        "disk_usage": disk.percent,
        "disk_detail": f"{format_bytes(disk.used)} / {format_bytes(disk.total)}",
        "uptime": format_uptime(uptime_seconds),
        "platform": platform.platform(),
        "services": get_service_health(),
    }


@app.route("/")
def dashboard():
    """Render the server health dashboard."""
    return render_template_string(TEMPLATE, metrics=collect_metrics())


@app.route("/health")
def health():
    """Provide a simple endpoint for load balancers and uptime checks."""
    return {"status": "healthy"}, 200


@app.route("/api/metrics")
def metrics_api():
    """Return live metrics as JSON for scripts or future integrations."""
    return jsonify(collect_metrics())


TEMPLATE = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="refresh" content="30">
  <title>MedCare Ubuntu Operations Dashboard</title>
  <style>
    :root { --navy: #12304a; --blue: #1976d2; --green: #16865a; --red: #c0392b; --bg: #f4f7fa; }
    * { box-sizing: border-box; }
    body { margin: 0; font-family: Arial, sans-serif; background: var(--bg); color: #243342; }
    header { background: var(--navy); color: white; padding: 24px 5%; }
    header h1 { margin: 0 0 6px; font-size: 26px; }
    header p { margin: 0; opacity: .85; }
    main { width: min(1100px, 90%); margin: 28px auto; }
    .meta, .grid { display: grid; gap: 16px; }
    .meta { grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); margin-bottom: 20px; }
    .grid { grid-template-columns: repeat(auto-fit, minmax(210px, 1fr)); }
    .card { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 8px rgba(18,48,74,.08); }
    .label { color: #617386; font-size: 13px; text-transform: uppercase; letter-spacing: .06em; }
    .value { margin-top: 10px; font-size: 27px; font-weight: bold; color: var(--navy); }
    .metric-bar { height: 8px; margin-top: 14px; overflow: hidden; border-radius: 4px; background: #e7edf2; }
    .metric-fill { height: 100%; background: var(--blue); }
    .detail { margin-top: 6px; color: #617386; font-size: 14px; }
    h2 { margin-top: 28px; color: var(--navy); }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 12px; border-bottom: 1px solid #e5ebf0; text-align: left; }
    .healthy { color: var(--green); font-weight: bold; }
    .not-detected { color: var(--red); font-weight: bold; }
    footer { margin: 30px 0; color: #708090; font-size: 13px; }
  </style>
</head>
<body>
  <header>
    <h1>MedCare Ubuntu Operations &amp; Monitoring Platform</h1>
    <p>Internal server health dashboard</p>
  </header>
  <main>
    <section class="meta">
      <div class="card"><div class="label">Hostname</div><div class="value">{{ metrics.hostname }}</div></div>
      <div class="card"><div class="label">Current Time</div><div class="value" style="font-size:20px">{{ metrics.current_time }}</div></div>
      <div class="card"><div class="label">Uptime</div><div class="value">{{ metrics.uptime }}</div></div>
    </section>
    <section class="grid">
      <div class="card"><div class="label">CPU Usage</div><div class="value">{{ metrics.cpu_usage }}%</div><div class="metric-bar"><div class="metric-fill" style="width: {{ metrics.cpu_usage }}%"></div></div></div>
      <div class="card"><div class="label">Memory Usage</div><div class="value">{{ metrics.memory_usage }}%</div><div class="detail">{{ metrics.memory_detail }}</div><div class="metric-bar"><div class="metric-fill" style="width: {{ metrics.memory_usage }}%"></div></div></div>
      <div class="card"><div class="label">Disk Usage</div><div class="value">{{ metrics.disk_usage }}%</div><div class="detail">{{ metrics.disk_detail }}</div><div class="metric-bar"><div class="metric-fill" style="width: {{ metrics.disk_usage }}%"></div></div></div>
    </section>
    <h2>Service Health</h2>
    <div class="card">
      <table>
        <thead><tr><th>Service process</th><th>Status</th></tr></thead>
        <tbody>
          {% for service in metrics.services %}
          <tr>
            <td>{{ service.name }}</td>
            <td class="{{ service.status|lower|replace(' ', '-') }}">{{ service.status }}</td>
          </tr>
          {% endfor %}
        </tbody>
      </table>
    </div>
    <footer>Platform: {{ metrics.platform }}. Dashboard refreshes every 30 seconds.</footer>
  </main>
</body>
</html>
"""


if __name__ == "__main__":
    # Listen on all interfaces so local or systemd runs can publish the dashboard.
    app.run(host="0.0.0.0", port=5000)
