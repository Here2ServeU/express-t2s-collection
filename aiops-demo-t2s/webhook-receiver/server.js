const express = require("express");

const app = express();
app.use(express.json({ limit: "2mb" }));

const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;
const SLACK_CHANNEL_NAME = process.env.SLACK_CHANNEL_NAME || "#aiops-demo";

async function postToSlack(text) {
  if (!SLACK_WEBHOOK_URL || SLACK_WEBHOOK_URL.includes("hooks.slack.com/services/XXX")) {
    console.log("[WARN] Slack webhook not set. Message would be:");
    console.log(text);
    return;
  }
  const payload = { text };
  const res = await fetch(SLACK_WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
  if (!res.ok) {
    const body = await res.text();
    console.error("[ERROR] Slack webhook failed:", res.status, body);
  }
}

app.post("/alertmanager", async (req, res) => {
  const data = req.body || {};
  const alerts = data.alerts || [];
  const status = data.status || "unknown";

  const lines = [];
  lines.push(`*AIOps Demo Alert* (${status}) → ${SLACK_CHANNEL_NAME}`);
  for (const a of alerts) {
    const name = a.labels?.alertname || "UnknownAlert";
    const severity = a.labels?.severity || "info";
    const summary = a.annotations?.summary || "";
    const desc = a.annotations?.description || "";
    lines.push(`• *${name}* (severity: ${severity})`);
    if (summary) lines.push(`  ↳ ${summary}`);
    if (desc) lines.push(`  ↳ ${desc}`);
  }

  try {
    await postToSlack(lines.join("\n"));
  } catch (e) {
    console.error(e);
  }

  res.json({ ok: true });
});

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.listen(5001, () => console.log("Webhook receiver listening on :5001"));
