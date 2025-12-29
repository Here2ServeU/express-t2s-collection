import numpy as np
from sklearn.ensemble import IsolationForest

# Load metrics
latency = np.loadtxt("latency.csv")

model = IsolationForest(contamination=0.02)
model.fit(latency.reshape(-1, 1))

pred = model.predict(latency.reshape(-1, 1))

anomalies = np.where(pred == -1)[0]
print("Anomalies detected at indexes:", anomalies)