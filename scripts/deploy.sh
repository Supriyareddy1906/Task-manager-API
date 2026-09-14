#!/usr/bin/env bash
#
# deploy.sh — runs ON the EC2 instance (invoked over SSH by GitHub Actions,
# or manually) to pull the latest image and restart the stack.
#
set -euo pipefail

APP_DIR="/home/ubuntu/Task-manager-API"
IMAGE_NAME="${DOCKER_IMAGE:-supriya9606/task-manager-api}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting deployment of ${IMAGE_NAME}:${IMAGE_TAG}"

if [ ! -d "$APP_DIR" ]; then
    log "ERROR: App directory $APP_DIR not found. Clone the repo there first."
    exit 1
fi

cd "$APP_DIR"

log "Pulling latest image..."
docker pull "${IMAGE_NAME}:${IMAGE_TAG}"

log "Updating docker-compose image reference..."
export DOCKER_IMAGE="$IMAGE_NAME"
export IMAGE_TAG="$IMAGE_TAG"

log "Restarting containers..."
docker compose pull app
docker compose up -d --remove-orphans

log "Cleaning up old dangling images..."
docker image prune -f

log "Waiting for app to become healthy..."
RETRIES=10
until curl -sf http://localhost:8000/health > /dev/null || [ "$RETRIES" -eq 0 ]; do
    RETRIES=$((RETRIES - 1))
    log "App not ready yet, retrying... ($RETRIES left)"
    sleep 3
done

if [ "$RETRIES" -eq 0 ]; then
    log "ERROR: App failed health check after deployment. Rolling back is recommended."
    docker compose logs app --tail=50
    exit 1
fi

log "Deployment successful. App is healthy."
