# Task Manager API — Automated Cloud Deployment & Monitoring Platform

A small FastAPI + PostgreSQL task-management REST API, built specifically to
demonstrate a full DevOps pipeline: GitHub → CI/CD (test/build/dockerize/push)
→ AWS EC2 (Docker) → Prometheus/Grafana monitoring → Alerts.

## Architecture

```
Developer → git push → GitHub
                          │
                    GitHub Actions
              1. Test   2. Build   3. Docker Build   4. Docker Push
                          │
                    Docker Hub (registry)
                          │
                    AWS EC2 (Docker + docker-compose)
                    ┌─────────────┬─────────────┐
                    │  app (API)  │  db (Postgres)│
                    └─────────────┴─────────────┘
                          │
              Prometheus  ← scrapes /metrics, node-exporter
                          │
                    Grafana dashboards
                          │
                    Alerts (Grafana/Alertmanager)
```

## Project structure

```
task-manager-api/
├── app/
│   ├── main.py          # FastAPI app: CRUD routes, /health, /metrics, chaos endpoints
│   ├── models.py        # SQLAlchemy Task model
│   ├── schemas.py        # Pydantic request/response schemas
│   ├── crud.py           # DB access functions
│   └── database.py       # DB engine/session setup
├── tests/
│   └── test_api.py       # Pytest suite (runs against in-memory SQLite)
├── monitoring/
│   ├── prometheus.yml    # Scrape config
│   └── alert_rules.yml   # Alert rules (app down, high error rate, latency, CPU)
├── scripts/
│   ├── provision_ec2.sh  # One-time EC2 setup: installs Docker/Compose
│   └── deploy.sh         # Pulls latest image + restarts stack, run on EC2
├── .github/workflows/
│   └── ci-cd.yml          # Test → Build → Push → Deploy pipeline
├── Dockerfile
├── docker-compose.yml     # app + db + prometheus + grafana + node-exporter
└── requirements.txt
```

## Local development

```bash
# 1. Clone and enter the repo
git clone <your-repo-url> && cd task-manager-api

# 2. Run everything locally
docker compose up -d --build

# 3. Check it's alive
curl http://localhost:8000/health

# 4. Try the API
curl -X POST http://localhost:8000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Set up pipeline", "priority": 1}'

curl http://localhost:8000/tasks

# 5. View metrics / dashboards
open http://localhost:8000/metrics   # raw Prometheus metrics
open http://localhost:9090           # Prometheus UI
open http://localhost:3000           # Grafana (admin/admin)
```

## Running tests locally

```bash
pip install -r requirements.txt
pytest tests/ -v
```

## Setting up AWS EC2

1. Launch an Ubuntu 22.04/24.04 EC2 instance (t2.micro is enough for a demo).
2. Open inbound ports in its Security Group: `22` (SSH), `8000` (API),
   `9090` (Prometheus), `3000` (Grafana).
3. SSH in and run the provisioning script:
   ```bash
   scp scripts/provision_ec2.sh ubuntu@<EC2_IP>:~
   ssh ubuntu@<EC2_IP>
   chmod +x provision_ec2.sh && ./provision_ec2.sh
   ```
4. Log out/in (for the docker group to apply), then run `scripts/deploy.sh`
   once manually to confirm it works before letting CI drive it.

## Setting up GitHub Actions

Add these repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `DOCKERHUB_USERNAME` | your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `EC2_HOST` | your EC2 instance's public IP |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | contents of your EC2 `.pem` private key |

Every push to `main` will now: run tests → build & push the Docker image →
SSH into EC2 and redeploy via `scripts/deploy.sh`.

## Demo script (for presenting the project)

1. Make a small code change, `git push` to `main`.
2. Show the GitHub Actions run: test → build → push → deploy, live.
3. Show the app running on the EC2 public IP.
4. Open Grafana, show the live request/latency dashboard.
5. Hit `curl http://<EC2_IP>:8000/simulate-error` a few times in a loop to
   trigger the `HighErrorRate` alert live.
6. Hit `/simulate-slow` to demonstrate the latency alert.
7. Show the alert firing in Prometheus/Grafana/Slack.

## Key endpoints

| Endpoint | Purpose |
|---|---|
| `GET /health` | Liveness/readiness check (used by monitoring & LB) |
| `GET /metrics` | Prometheus-format metrics |
| `POST /tasks`, `GET /tasks`, `GET/PUT/DELETE /tasks/{id}` | Task CRUD |
| `GET /simulate-error` | Deliberately throws a 500 (for alert demos) |
| `GET /simulate-slow` | Deliberately slow response (for latency demos) |
