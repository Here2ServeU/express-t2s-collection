#!/usr/bin/env python3
"""
T2S AIOps: Log pattern clustering (TF-IDF + KMeans).

Input: text file with 1 log line per row (or CSV with 'message' column).
Output: ./reports/log_clusters.json

Usage:
  python sre/aiops/log-pattern-cluster.py --input data/app.log --k 6

Notes:
  Requires: scikit-learn (pip install scikit-learn)
"""
import argparse
import json
from pathlib import Path

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--k", type=int, default=6)
    ap.add_argument("--out", default="reports/log_clusters.json")
    return ap.parse_args()

def read_lines(path: str):
    p = Path(path)
    if p.suffix.lower() == ".csv":
        import csv
        lines = []
        with p.open(newline="", encoding="utf-8") as f:
            r = csv.DictReader(f)
            for row in r:
                if "message" in row and row["message"]:
                    lines.append(row["message"])
        return lines
    return [l.strip() for l in p.read_text(encoding="utf-8", errors="ignore").splitlines() if l.strip()]

def main():
    args = parse_args()
    lines = read_lines(args.input)
    if not lines:
        raise SystemExit("No log lines found.")

    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.cluster import KMeans

    vec = TfidfVectorizer(stop_words="english", max_features=5000)
    X = vec.fit_transform(lines)

    km = KMeans(n_clusters=args.k, n_init=10, random_state=42)
    labels = km.fit_predict(X)

    clusters = {}
    for i, lbl in enumerate(labels):
        clusters.setdefault(str(lbl), []).append(lines[i])

    report = {
        "input": args.input,
        "k": args.k,
        "cluster_sizes": {k: len(v) for k, v in clusters.items()},
        "sample_messages": {k: v[:10] for k, v in clusters.items()}
    }

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.out).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"Wrote: {args.out}")

if __name__ == "__main__":
    main()
