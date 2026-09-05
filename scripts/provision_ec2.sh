#!/usr/bin/env bash
#
# provision_ec2.sh — run ONCE on a fresh EC2 instance (Ubuntu 22.04/24.04)
# to install Docker, Docker Compose, and prepare the app directory.
#
set -euo pipefail

echo "Updating packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing prerequisites..."
sudo apt-get install -y ca-certificates curl gnupg git

echo "Installing Docker Engine..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Adding current user to docker group (log out/in to take effect)..."
sudo usermod -aG docker "$USER"

echo "Cloning application repo..."
APP_DIR="/home/ubuntu/task-manager-api"
if [ ! -d "$APP_DIR" ]; then
    git clone https://github.com/YOUR_USERNAME/task-manager-api.git "$APP_DIR"
else
    echo "Repo already exists at $APP_DIR, skipping clone."
fi

echo "Provisioning complete. Log out and back in for docker group changes to apply,"
echo "then run scripts/deploy.sh (or let GitHub Actions do it) to start the app."
