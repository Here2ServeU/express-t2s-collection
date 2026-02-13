import express from "express";
import cors from "cors";

const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) => {
  res.json({ ok: true, service: "node-api", time: new Date().toISOString() });
});

// BANK (FinTech)
let account = { user: "demo", balance: 1000 };

app.post("/bank/login", (req, res) => {
  const { username } = req.body || {};
  res.json({ ok: true, message: `Welcome, ${username || "demo"}!`, token: "fake-token" });
});

app.get("/bank/balance", (req, res) => {
  res.json({ ok: true, user: account.user, balance: account.balance });
});

app.post("/bank/transfer", (req, res) => {
  const { amount } = req.body || {};
  const n = Number(amount || 0);
  if (!Number.isFinite(n) || n <= 0) return res.status(400).json({ ok: false, error: "amount must be positive" });

  // simulate occasional failure
  if (Math.random() < 0.05) return res.status(500).json({ ok: false, error: "simulated bank error" });

  account.balance = Math.max(0, account.balance - n);
  res.json({ ok: true, transferred: n, newBalance: account.balance });
});

// HOSPITAL (Healthcare)
app.post("/hospital/checkin", (req, res) => {
  const { patientId } = req.body || {};
  res.json({ ok: true, message: `Patient ${patientId || "P-0001"} checked in.` });
});

app.get("/hospital/vitals", (req, res) => {
  const vitals = {
    heartRate: 60 + Math.floor(Math.random() * 50),
    spo2: 92 + Math.floor(Math.random() * 8),
    systolic: 100 + Math.floor(Math.random() * 40),
    diastolic: 60 + Math.floor(Math.random() * 25)
  };
  const slow = Math.random() < 0.10;
  const delayMs = slow ? 900 + Math.floor(Math.random() * 600) : 0;

  setTimeout(() => res.json({ ok: true, vitals, delayMs }), delayMs);
});

app.post("/hospital/med-order", (req, res) => {
  const { med, dose } = req.body || {};
  res.json({ ok: true, message: `Order received: ${med || "Medication"} ${dose || "N/A"}` });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`node-api listening on ${PORT}`));
