import pandas as pd

df = pd.read_csv("metrics.csv")

avg_cpu = df["cpu"].mean()

if avg_cpu > 70:
    print("Recommended: Increase replicas by +2")
elif avg_cpu < 30:
    print("Recommended: Decrease replicas by -1")
else:
    print("No change needed")