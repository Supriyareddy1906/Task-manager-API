#!/usr/bin/env bash
#
# set_webhook.sh — stores your Discord webhook URL in a protected config file
# so monitor.sh can read it without exposing it in `crontab -l` or shell history.
#
# Usage: sudo ./set_webhook.sh "https://discord.com/api/webhooks/xxxx/yyyy"
#
set -euo pipefail

CONFIG_FILE="/etc/task-manager-monitor.conf"

if [ "$#" -ne 1 ]; then
    echo "Usage: sudo $0 <DISCORD_WEBHOOK_URL>"
    exit 1
fi

echo "DISCORD_WEBHOOK_URL=\"$1\"" | sudo tee "$CONFIG_FILE" > /dev/null
sudo chmod 600 "$CONFIG_FILE"
sudo chown root:root "$CONFIG_FILE"

echo "Webhook URL saved to $CONFIG_FILE (permissions locked to root)."
