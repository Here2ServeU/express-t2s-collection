from prophet import Prophet
import pandas as pd

df = pd.read_csv("metrics.csv")
df = df.rename(columns={"timestamp": "ds", "value": "y"})

model = Prophet()
model.fit(df)

future = model.make_future_dataframe(periods=1440, freq="min")
forecast = model.predict(future)

forecast[['ds','yhat','yhat_lower','yhat_upper']].to_csv("forecast.csv", index=False)