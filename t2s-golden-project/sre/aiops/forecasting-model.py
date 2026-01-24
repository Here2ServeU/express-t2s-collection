#!/usr/bin/env python3
"""
T2S AIOps: Simple forecasting using exponential smoothing.

Input: CSV with columns: timestamp,value
Output: forecasts to ./reports/forecast.json

Usage:
  python sre/aiops/forecasting-model.py --input data/metric.csv --alpha 0.3 --horizon 20
"""
import argparse
import csv
import json
from pathlib import Path

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--alpha", type=float, default=0.3, help="Smoothing factor (0..1)")
    ap.add_argument("--horizon", type=int, default=20, help="Number of future points")
    ap.add_argument("--out", default="reports/forecast.json")
    return ap.parse_args()

def main():
    args = parse_args()
    series = []
    with open(args.input, newline="", encoding="utf-8") as f:
        r = csv.DictReader(f)
        for row in r:
            series.append(float(row["value"]))

    if not series:
        raise SystemExit("No values found. Ensure CSV has timestamp,value columns.")

    alpha = args.alpha
    level = series[0]
    fitted = []
    for x in series:
        level = alpha * x + (1 - alpha) * level
        fitted.append(level)

    last = fitted[-1]
    forecast = [last for _ in range(args.horizon)]

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({
            "input": args.input,
            "alpha": alpha,
            "horizon": args.horizon,
            "last_level": last,
            "forecast": forecast
        }, f, indent=2)

    print(f"Forecast written: {args.out} (horizon={args.horizon}, last={last:.4f})")

if __name__ == "__main__":
    main()
