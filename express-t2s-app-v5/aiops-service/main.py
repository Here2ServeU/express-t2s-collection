from fastapi import FastAPI, Response
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest
import time

app = FastAPI(title="AIOps Demo Service")

# ---------------------------
# Prometheus Metrics
# ---------------------------
REQUEST_COUNT = Counter(
    "aiops_requests_total",
    "Total number of AIOps API requests",
    ["endpoint"]
)

LATENCY = Histogram(
    "aiops_request_latency_seconds",
    "Latency for AIOps endpoint",
    ["endpoint"],
    buckets=[0.05, 0.1, 0.25, 0.5, 1, 2, 5]
)

# ---------------------------
# Dashboard HTML
# ---------------------------
@app.get("/", response_class=HTMLResponse)
def dashboard():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>AIOps Dashboard</title>
        <style>
            body { font-family: Arial, sans-serif; background: #f8f9fa; padding: 40px; }
            .container { max-width: 800px; margin: auto; padding: 20px;
                background: white; border-radius: 10px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
            h1 { color: #1e3a8a; }
            h2 { color: #2563eb; margin-top: 30px; }
            label { font-weight: bold; margin-top: 10px; display: block; }
            input { width: 100%; padding: 10px; margin-top: 5px;
                border-radius: 6px; border: 1px solid #d1d5db; }
            button { margin-top: 10px; padding: 12px 20px; background: #2563eb;
                color: white; border: none; border-radius: 6px; cursor: pointer; }
            button:hover { background: #1d4ed8; }
            .result-box { margin-top: 10px; background: #f3f4f6; padding: 15px;
                border-radius: 8px; white-space: pre-wrap; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>AIOps Dashboard</h1>
            <p>Predict risk, detect anomalies, and estimate cloud cost.</p>

            <h2>Incident Risk Prediction</h2>
            <label>CPU Usage (%)</label>
            <input id="cpu" type="number" value="50">

            <label>Memory Usage (%)</label>
            <input id="memory" type="number" value="40">

            <label>Latency (ms)</label>
            <input id="latency" type="number" placeholder="e.g. 120">

            <button onclick="predict()">Run Prediction</button>
            <div id="predict-output" class="result-box">Waiting...</div>

            <h2>FinOps Cost Estimator</h2>
            <label>CPU (millicores)</label>
            <input id="cpu_m" type="number" value="300">

            <label>Memory (MB)</label>
            <input id="mem_m" type="number" value="512">

            <button onclick="finops()">Estimate Cost</button>
            <div id="finops-output" class="result-box">Waiting...</div>
        </div>

        <script>
            async function predict() {
                const cpu = Number(document.getElementById("cpu").value);
                const memory = Number(document.getElementById("memory").value);
                let latency_raw = document.getElementById("latency").value;
                const latency = latency_raw === "" ? null : Number(latency_raw);

                const res = await fetch("/predict", {
                    method: "POST",
                    headers: {"Content-Type": "application/json"},
                    body: JSON.stringify({ cpu, memory, latency_ms: latency })
                });

                const data = await res.json();
                document.getElementById("predict-output").innerText =
                    "Risk Score: " + data.risk_score +
                    "\\nSeverity: " + data.severity +
                    "\\nMessage: " + data.message;
            }

            async function finops() {
                const cpu_m = Number(document.getElementById("cpu_m").value);
                const mem_m = Number(document.getElementById("mem_m").value);

                const res = await fetch("/finops", {
                    method: "POST",
                    headers: {"Content-Type": "application/json"},
                    body: JSON.stringify({ cpu_millicores: cpu_m, memory_mb: mem_m })
                });

                const data = await res.json();
                document.getElementById("finops-output").innerText =
                    "Estimated Monthly Cost: $" + data.estimated_monthly_cost +
                    "\\nRecommendation: " + data.recommendation;
            }
        </script>
    </body>
    </html>
    """


# ---------------------------
# Models
# ---------------------------
class PredictRequest(BaseModel):
    cpu: float
    memory: float
    latency_ms: float | None = None

class FinOpsRequest(BaseModel):
    cpu_millicores: float
    memory_mb: float


# ---------------------------
# Prediction Endpoint
# ---------------------------
@app.post("/predict")
def predict(req: PredictRequest):
    REQUEST_COUNT.labels(endpoint="predict").inc()
    with LATENCY.labels(endpoint="predict").time():
        score = (req.cpu * 0.4) + (req.memory * 0.3)
        if req.latency_ms:
            score += req.latency_ms * 0.2

        severity = "low"
        if score > 70:
            severity = "high"
        elif score > 40:
            severity = "medium"

        return {
            "risk_score": round(score, 2),
            "severity": severity,
            "message": "System risk evaluated successfully"
        }


# ---------------------------
# FinOps Endpoint
# ---------------------------
@app.post("/finops")
def finops(req: FinOpsRequest):
    REQUEST_COUNT.labels(endpoint="finops").inc()
    with LATENCY.labels(endpoint="finops").time():
        cost_cpu = req.cpu_millicores * 0.00001
        cost_mem = req.memory_mb * 0.000005
        total = round(cost_cpu + cost_mem, 4)

        rec = "Right-sized."
        if req.cpu_millicores > 400:
            rec = "High CPU — consider reducing limits."
        if req.memory_mb > 800:
            rec = "High memory — check workload pattern."

        return {
            "estimated_monthly_cost": total,
            "recommendation": rec
        }


# ---------------------------
# Prometheus Metrics Endpoint
# ---------------------------
@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type="text/plain")
