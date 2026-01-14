# Slack Setup (Incoming Webhook)

1. In Slack, go to:
   - Workspace Settings → Apps → (or browse Slack App Directory)
2. Search: **Incoming Webhooks**
3. Add to Slack → Choose a channel (example: #aiops-demo)
4. Copy the generated Webhook URL
5. Put it into `.env`:

```bash
cp .env.example .env
# edit .env and set:
SLACK_WEBHOOK_URL=...
```

Then restart the stack:
```bash
docker compose up -d --build
```
