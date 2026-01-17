# Setup Guide for Integrating Slack Incoming Webhooks into Your Project

---

## 1. Create a Slack App

First, you need to generate a Webhook URL from the Slack API dashboard:

1. Navigate to the **[Slack Apps Dashboard](https://api.slack.com/apps)**.
2. Click **Create New App** and select **From scratch**.
3. Enter an **App Name** and select the **Workspace** where you want to receive notifications.
4. Click **Create App**.

## 2. Enable Incoming Webhooks

1. Under the **Features** section in the left sidebar, click **Incoming Webhooks**.
2. Toggle the switch to **On** to activate webhooks.
3. Click the **Add New Webhook to Workspace** button at the bottom.
4. Select the specific **Channel** where the app should post messages and click **Allow**.
5. Locate your new **Webhook URL** and click **Copy**.

## 3. Configure the Environment

Apply the copied URL to your project's configuration:

* **Initialize your .env file:**
```bash
cp .env.example .env

```


* **Update variables:**
Open the `.env` file and set the following value:
```bash
SLACK_WEBHOOK_URL=your_copied_webhook_url_here

```



## 4. Deploy Changes

Restart your Docker containers to apply the new environment variables:

```bash
docker compose up -d --build

```

