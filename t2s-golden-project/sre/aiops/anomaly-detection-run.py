#!/usr/bin/env python3
"""
T2S AIOps: Simple anomaly detection (rolling z-score) for time-series metrics.

Input: CSV with columns: timestamp,value
  - timestamp can be any string; it's carried through
  - value must be numeric

Usage:
  python sre/aiops/anomaly-detection-run.py --input data/metric.csv --window 30 --z 3.0

Output:
  Prints anomalies and writes a JSON report to ./reports/anomalies.json
"""
import argparse
import csv
import json
import math
from pathlib import Path
from statistics import mean, pstdev

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="CSV file with timestamp,value")
    ap.add_argument("--window", type=int, default=30, help="Rolling window size")
    ap.add_argument("--z", type=float, default=3.0, help="Z-score threshold")
    ap.add_argument("--out", default="reports/anomalies.json", help="Output JSON report path")
    return ap.parse_args()

def main():
    args = parse_args()
    rows = []
    with open(args.input, newline="", encoding="utf-8") as f:
        r = csv.DictReader(f)
        for row in r:
            rows.append({"timestamp": row["timestamp"], "value": float(row["value"])})

    anomalies = []
    values = [r["value"] for r in rows]

    for i in range(len(values)):
        if i < args.window:
            continue
        window_vals = values[i-args.window:i]
        mu = mean(window_vals)
        sigma = pstdev(window_vals) or 1e-9
        zscore = (values[i] - mu) / sigma
        if abs(zscore) >= args.z:
            anomalies.append({
                "index": i,
                "timestamp": rows[i]["timestamp"],
                "value": values[i],
                "mean": mu,
                "stddev": sigma,
                "zscore": zscore
            })

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"input": args.input, "window": args.window, "threshold_z": args.z, "anomalies": anomalies}, f, indent=2)

    print(f"Scanned {len(values)} points. Found {len(anomalies)} anomalies (|z| >= {args.z}).")
    for a in anomalies[:25]:
        print(f"- {a['timestamp']} value={a['value']:.4f} z={a['zscore']:.2f} (mu={a['mean']:.4f}, sd={a['stddev']:.4f})")
    if len(anomalies) > 25:
        print(f"... ({len(anomalies)-25} more)")

    print(f"Report written: {args.out}")

if __name__ == "__main__":
    main()
