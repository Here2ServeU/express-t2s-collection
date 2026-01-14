const express = require("express");
const path = require("path");
const client = require("prom-client");

const app = express();
const port = process.env.PORT || 3000;

// Serve static UI from app/public
const publicDir = path.join(__dirname, "public");
app.use(express.static(publicDir));

/* -----------------------------
   Prometheus metrics setup
------------------------------ */
client.collectDefaultMetrics();
const register = client.register;

const httpRequestsTotal = new client.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status"],
});

const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request duration in seconds",
  labelNames: ["method", "route", "status"],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
});

const cpuBurnActive = new client.Gauge({
  name: "demo_cpu_burn_active",
  help: "1 when /burn is actively burning CPU, else 0",
});

// ✅ Warm up metrics so they always show up in /metrics immediately
function warmUpMetrics() {
  const baseLabels = { method: "GET", route: "/warmup", status: "200" };

  // Create one sample for counter
  httpRequestsTotal.inc(baseLabels, 0);

  // Create one sample for histogram
  httpRequestDuration.observe(baseLabels, 0);

  // Gauge already emits value; ensure it has a value
  cpuBurnActive.set(0);
}
warmUpMetrics();

/**
 * Track latency + request counts for every response
 */
app.use((req, res, next) => {
  const startTimer = httpRequestDuration.startTimer();

  res.on("finish", () => {
    const route = req.route?.path || req.path || "unknown";
    const status = String(res.statusCode);

    httpRequestsTotal.inc({ method: req.method, route, status });
    startTimer({ method: req.method, route, status });
  });

  next();
});

/* -----------------------------
   Demo endpoints
------------------------------ */

// Health endpoint
app.get("/health", (req, res) => res.status(200).json({ status: "ok" }));

// Optional JSON endpoint
app.get("/api", (req, res) => {
  res.json({ message: "AIOps demo app running", time: new Date().toISOString() });
});

// Simulated error endpoint
app.get("/error", (req, res) => {
  const rateRaw = Number(req.query.rate ?? "0.7");
  const rate = Number.isFinite(rateRaw) ? Math.min(Math.max(rateRaw, 0), 1) : 0.7;

  if (Math.random() < rate) {
    return res.status(500).json({ status: "error", message: "Simulated 500 error" });
  }
  return res.json({ status: "ok", message: "No error this time" });
});

// CPU burn simulation endpoint
app.get("/burn", (req, res) => {
  const secondsRaw = Number(req.query.seconds ?? "10");
  const seconds = Number.isFinite(secondsRaw)
    ? Math.min(Math.max(secondsRaw, 1), 60)
    : 10;

  cpuBurnActive.set(1);

  const start = Date.now();
  while (Date.now() - start < seconds * 1000) {
    Math.sqrt(Math.random() * 1000000);
  }

  cpuBurnActive.set(0);
  return res.json({ status: "ok", burned_seconds: seconds });
});

// Prometheus metrics endpoint
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

// SPA fallback
app.get("*", (req, res) => {
  res.sendFile(path.join(publicDir, "index.html"));
});

app.listen(port, () => {
  console.log(`AIOps demo app listening on port ${port}`);
  console.log(`UI:      http://localhost:${port}/`);
  console.log(`Health:  http://localhost:${port}/health`);
  console.log(`Metrics: http://localhost:${port}/metrics`);
});
