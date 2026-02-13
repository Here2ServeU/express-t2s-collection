import argparse, random, time, requests

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--base-url", default="http://localhost:3000")
    p.add_argument("--seconds", type=int, default=30)
    args = p.parse_args()

    end = time.time() + args.seconds
    ok = fail = 0
    print(f"[bank-sim] traffic → {args.base_url} for {args.seconds}s")

    while time.time() < end:
        action = random.choice(["balance","transfer"])
        try:
            if action == "balance":
                r = requests.get(f"{args.base_url}/bank/balance", timeout=2)
            else:
                amt = random.randint(1, 100)
                r = requests.post(f"{args.base_url}/bank/transfer", json={"amount": amt}, timeout=3)
            ok += 1 if 200 <= r.status_code < 300 else 0
            fail += 1 if r.status_code >= 300 else 0
        except Exception:
            fail += 1
        time.sleep(random.uniform(0.05, 0.25))
    print(f"[bank-sim] done ok={ok} fail={fail}")

if __name__ == "__main__":
    main()
