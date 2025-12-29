// =========================
// Express App + Prometheus Metrics + Static Website
// =========================

const express = require('express');
const path = require('path');
const client = require('prom-client');

const app = express();

// 1) Serve your static website from /public
app.use(express.static(path.join(__dirname, 'public')));

// 2) Collect default Node.js metrics
client.collectDefaultMetrics();

// 3) Request duration histogram
const httpRequestDuration = new client.Histogram({
  name: 'express_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.1, 0.3, 0.5, 1, 2, 5]
});

// 4) Middleware to measure request timing
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on('finish', () => {
    end({
      method: req.method,
      route: req.route?.path || req.path,
      status: res.statusCode
    });
  });
  next();
});

// 5) Serve index.html explicitly for '/'
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 6) Kubernetes health probe
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// 7) Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  } catch (err) {
    res.status(500).end(err.toString());
  }
});

// 8) Start server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Express Web App running on port ${PORT}`);
});
