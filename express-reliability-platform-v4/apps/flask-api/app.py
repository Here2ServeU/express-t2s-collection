from flask import Flask, jsonify, request
import random
import os
import time

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify(ok=True, service="flask-api", time=time.time())

@app.get("/risk-score")
def risk_score():
    score = random.randint(1, 100)
    label = "LOW" if score < 35 else ("MEDIUM" if score < 70 else "HIGH")
    return jsonify(ok=True, riskScore=score, riskLabel=label)

@app.post("/incident-summary")
def incident_summary():
    data = request.get_json(silent=True) or {}
    summary = {
        "title": data.get("title", "Incident Summary"),
        "signals": data.get("signals", []),
        "recommendation": "Check service health, review logs, consider rollback if errors persist."
    }
    return jsonify(ok=True, summary=summary)

@app.post("/health-analysis")
def health_analysis():
    data = request.get_json(silent=True) or {}
    hr = int(data.get("heartRate", 80))
    spo2 = int(data.get("spo2", 96))
    status = "OK"
    if hr > 120 or spo2 < 92:
        status = "ATTENTION"
    return jsonify(ok=True, status=status, input=data)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)
