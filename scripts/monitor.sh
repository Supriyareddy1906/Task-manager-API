#!/usr/bin/env bash
#
# monitor.sh — health & resource monitor for the Task Manager app.
# Meant to be run periodically via cron on the EC2 instance.
#
# What it checks:
#   1. Are the Docker containers (app, db) running?
#   2. Does the /health endpoint respond with 200?
#   3. Is CPU / memory / disk usage within safe limits?
# What it does on failure:
#   - Logs the issue to a log file
#   - Sends an alert message to a Discord channel via webhook
#
set -uo pipefail

# ---------- Configuration ----------
APP_URL="http://localhost:8000/health"
LOG_FILE="/var/log/task-manager-monitor.log"
CONFIG_FILE="/etc/task-manager-monitor.conf"   # holds DISCORD_WEBHOOK_URL=... , chmod 600
CPU_THRESHOLD=85      # percent
MEM_THRESHOLD=85      # percent
DISK_THRESHOLD=85     # percent

# Load the webhook URL from a restricted config file (not from cron/env directly)
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"

# ---------- Helpers ----------
timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

log() {
    echo "[$(timestamp)] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local message="$1"
    log "ALERT: $message"

    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
        curl -s -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"🚨 **Task Manager Alert** [$(timestamp)]\n${message}\"}" \
             "$DISCORD_WEBHOOK_URL" > /dev/null
    else
        log "WARNING: DISCORD_WEBHOOK_URL not set, skipping webhook alert."
    fi
}

# ---------- 1. Container status check ----------
for container in taskmanager-app taskmanager-db; do
    status=$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)
    if [ "$status" != "true" ]; then
        send_alert "Container '${container}' is NOT running (status: ${status:-not found})."
    fi
done

# ---------- 2. App health endpoint check ----------
http_code=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL" --max-time 5)
if [ "$http_code" != "200" ]; then
    send_alert "Health check failed. GET ${APP_URL} returned HTTP ${http_code}."
else
    log "Health check OK (HTTP $http_code)."
fi

# ---------- 3. CPU usage check ----------
cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $4}' | grep -o '[0-9.]*')
cpu_usage=$(awk "BEGIN {printf \"%.0f\", 100 - $cpu_idle}")
if [ "$cpu_usage" -ge "$CPU_THRESHOLD" ]; then
    send_alert "High CPU usage: ${cpu_usage}% (threshold ${CPU_THRESHOLD}%)."
else
    log "CPU usage OK (${cpu_usage}%)."
fi

# ---------- 4. Memory usage check ----------
mem_usage=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
if [ "$mem_usage" -ge "$MEM_THRESHOLD" ]; then
    send_alert "High memory usage: ${mem_usage}% (threshold ${MEM_THRESHOLD}%)."
else
    log "Memory usage OK (${mem_usage}%)."
fi

# ---------- 5. Disk usage check ----------
disk_usage=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')
if [ "$disk_usage" -ge "$DISK_THRESHOLD" ]; then
    send_alert "High disk usage: ${disk_usage}% (threshold ${DISK_THRESHOLD}%)."
else
    log "Disk usage OK (${disk_usage}%)."
fi

log "Monitor check complete."
