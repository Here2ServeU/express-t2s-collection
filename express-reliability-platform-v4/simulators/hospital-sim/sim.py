import argparse, random, time, requests

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--base-url", default="http://localhost:3000")
    p.add_argument("--seconds", type=int, default=30)
    args = p.parse_args()

    end = time.time() + args.seconds
    ok = slow = fail = 0
    print(f"[hospital-sim] telemetry → {args.base_url} for {args.seconds}s")

    while time.time() < end:
        try:
            r = requests.get(f"{args.base_url}/hospital/vitals", timeout=5)
            data = r.json()
            if data.get("delayMs", 0) > 0: slow += 1
            ok += 1 if 200 <= r.status_code < 300 else 0
            fail += 1 if r.status_code >= 300 else 0
        except Exception:
            fail += 1
        time.sleep(random.uniform(0.02, 0.15))
    print(f"[hospital-sim] done ok={ok} slow={slow} fail={fail}")

if __name__ == "__main__":
    main()
