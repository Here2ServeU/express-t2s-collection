#!/usr/bin/env python3
"""
T2S AIOps: Simple autoscaling recommendation based on forecast and SLO target.

Inputs:
  - forecast.json from forecasting-model.py
  - current replicas
  - target utilization (e.g., 0.65)
  - max replicas limit

Usage:
  python sre/aiops/autoscaling-ml-recommender.py --forecast reports/forecast.json --replicas 2 --target 0.65 --max 10
"""
import argparse
import json
import math

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--forecast", required=True)
    ap.add_argument("--replicas", type=int, required=True)
    ap.add_argument("--target", type=float, default=0.65)
    ap.add_argument("--max", type=int, default=10)
    return ap.parse_args()

def main():
    args = parse_args()
    data = json.loads(open(args.forecast, encoding="utf-8").read())
    forecast = data.get("forecast", [])
    if not forecast:
        raise SystemExit("Forecast is empty.")

    peak = max(forecast)
    # Interpret forecast as "relative load" and recommend replicas scaling linearly.
    # This is a demo heuristic: in real systems you'd use request rate, latency, CPU, etc.
    desired = math.ceil(args.replicas * (peak / max(peak, 1e-9)) / args.target)
    desired = max(1, min(desired, args.max))

    print("Autoscaling Recommendation")
    print(f"- Current replicas: {args.replicas}")
    print(f"- Target utilization: {args.target}")
    print(f"- Forecast peak: {peak:.4f}")
    print(f"- Recommended replicas: {desired}")
    print("Next step: apply via GitOps by updating Helm values in gitops/ environments.")

if __name__ == "__main__":
    main()
