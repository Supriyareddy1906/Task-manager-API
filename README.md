# Automated Cloud Deployment & Monitoring Platform

A DevOps project that automates the testing, containerization, deployment, and monitoring of a Task Manager REST API.

The project demonstrates an end-to-end workflow using **GitHub, GitHub Actions, Docker, Docker Hub, AWS EC2, Shell Scripting, Cron, and Discord alerts**.

## Architecture

```text
Developer
    │
    │ git push
    ▼
GitHub Repository
    │
    ▼
GitHub Actions
    │
    ├── Run Tests
    │
    ├── Build Docker Image
    │
    └── Push Image
          │
          ▼
      Docker Hub
          │
          │ Pull latest image
          ▼
       AWS EC2
          │
          ├───────────────┐
          │               │
          ▼               ▼
   Task Manager API    PostgreSQL
     (Docker)           (Docker)
          │
          ▼
     Health Check
          │
          ▼
    Shell Monitoring
          │
     ┌────┼────┐
     ▼    ▼    ▼
    CPU  RAM  Disk
          │
          ▼
        Cron
   (runs every minute)
          │
          ▼
    Discord Alert
   when an issue occurs
```

## Project Overview

The **Task Manager API** is a simple REST API developed using FastAPI and PostgreSQL.

The main purpose of this project is not just the application itself, but to build an automated DevOps workflow around it.

The platform provides:

* Automated testing using GitHub Actions
* Docker image creation
* Docker Hub image publishing
* Automated deployment to AWS EC2
* PostgreSQL database running in Docker
* Application health monitoring
* CPU, memory, and disk monitoring
* Scheduled monitoring using Cron
* Discord notifications when failures are detected

## Technologies Used

| Technology       | Purpose                                           |
| ---------------- | ------------------------------------------------- |
| Linux            | Server administration and command-line operations |
| Shell Scripting  | Deployment and monitoring automation              |
| Git              | Version control                                   |
| GitHub           | Source code management                            |
| GitHub Actions   | CI/CD automation                                  |
| Python / FastAPI | REST API application                              |
| PostgreSQL       | Application database                              |
| Docker           | Application and database containers               |
| Docker Compose   | Managing multiple containers                      |
| Docker Hub       | Container image registry                          |
| AWS EC2          | Cloud deployment server                           |
| Cron             | Scheduled monitoring                              |
| Discord Webhook  | Monitoring alerts                                 |

## Application Features

The Task Manager API provides basic CRUD operations for tasks.

### Main Endpoints

| Endpoint              | Purpose                                 |
| --------------------- | --------------------------------------- |
| `GET /health`         | Checks application and database health  |
| `POST /tasks`         | Creates a new task                      |
| `GET /tasks`          | Retrieves all tasks                     |
| `GET /tasks/{id}`     | Retrieves a specific task               |
| `PUT /tasks/{id}`     | Updates a task                          |
| `DELETE /tasks/{id}`  | Deletes a task                          |
| `GET /simulate-error` | Simulates an application failure        |
| `GET /simulate-slow`  | Simulates a slow response               |
| `GET /docs`           | Opens the FastAPI Swagger documentation |

## Project Structure

```text
Task-manager-API/
│
├── app/
│   ├── main.py
│   ├── models.py
│   ├── schemas.py
│   ├── crud.py
│   └── database.py
│
├── tests/
│   └── test_api.py
│
├── scripts/
│   ├── provision_ec2.sh
│   ├── deploy.sh
│   ├── monitor.sh
│   └── set_webhook.sh
│
├── .github/
│   └── workflows/
│       └── ci-cd.yml
│
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## CI/CD Workflow

Whenever code is pushed to the `main` branch, GitHub Actions automatically starts the pipeline.

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ▼
Run Python Tests
   │
   ▼
Build Docker Image
   │
   ▼
Push Image to Docker Hub
   │
   ▼
Connect to AWS EC2
   │
   ▼
Pull Latest Docker Image
   │
   ▼
Restart Application
   │
   ▼
Health Check
```

### Pipeline Stages

**1. Test**

The project runs the Pytest test suite before building the Docker image.

**2. Build**

A Docker image is created using the project `Dockerfile`.

**3. Push**

The image is pushed to Docker Hub.

**4. Deploy**

GitHub Actions connects to the EC2 server through SSH and runs the deployment script.

**5. Health Check**

After deployment, the application health endpoint is checked to verify that the application is running correctly.

## Docker

The application and PostgreSQL database run as separate Docker containers.

```text
Docker
│
├── taskmanager-app
│      └── FastAPI Application
│
└── taskmanager-db
       └── PostgreSQL Database
```

The application container exposes port `8000`.

The application can be accessed through:

```text
http://<EC2_PUBLIC_IP>:8000/docs
```

## Monitoring

A custom Shell script is used for server and application monitoring.

The monitoring script checks:

* Docker container status
* Application health
* CPU usage
* Memory usage
* Disk usage

Example:

```text
Container       → Running?
Health Check    → Healthy?
CPU Usage       → Within limit?
Memory Usage    → Within limit?
Disk Usage      → Within limit?
```

Monitoring results are stored in:

```text
/var/log/task-manager-monitor.log
```

## Cron Automation

The monitoring script is scheduled using Linux Cron.

The monitoring job runs automatically every minute.

```text
* * * * * /home/ubuntu/Task-manager-API/scripts/monitor.sh
```

This means the server does not require manual monitoring.

## Discord Alerts

When the monitoring script detects a problem, it sends an alert to a Discord channel using a Discord webhook.

For example, if the application container stops:

```text
ALERT: Container 'taskmanager-app' is NOT running
```

The alert is automatically sent to the configured Discord monitoring channel.

## Failure Monitoring Flow

```text
Application / Server
        │
        ▼
    monitor.sh
        │
        ├── Container Check
        ├── Health Check
        ├── CPU Check
        ├── Memory Check
        └── Disk Check
                │
                ▼
          Problem Found?
             /     \
           No       Yes
           │         │
           ▼         ▼
         Log      Discord
       Status      Alert
```

## Testing the Monitoring System

The monitoring system can be tested by intentionally stopping the application container:

```bash
docker stop taskmanager-app
```

The monitoring script detects that the container is not running and sends a Discord alert.

The application can then be started again:

```bash
docker start taskmanager-app
```

Health can be verified using:

```bash
curl http://localhost:8000/health
```

Expected response:

```text
{"status":"healthy","db":"ok"}
```

## Running Tests

Install the project dependencies:

```bash
pip install -r requirements.txt
```

Run the test suite:

```bash
pytest tests/ -v
```

## AWS EC2 Deployment

The application is deployed on an Ubuntu AWS EC2 instance.

The EC2 server is responsible for:

* Running Docker
* Running the FastAPI application
* Running PostgreSQL
* Executing deployment scripts
* Running the monitoring Cron job
* Sending monitoring alerts

Required security-group access:

```text
22    → SSH
8000  → FastAPI application
```

## Docker Hub

The application Docker image is stored in Docker Hub.

```text
supriya9606/task-manager-api
```

The CI/CD pipeline automatically builds and pushes updated images whenever changes are pushed to the main branch.

## Key DevOps Scripts

### `provision_ec2.sh`

Performs the initial EC2 server setup, including Docker installation and configuration.

### `deploy.sh`

Handles application deployment by pulling the Docker image and restarting the application stack.

### `monitor.sh`

Checks application and server health and sends Discord alerts when problems are detected.

### `set_webhook.sh`

Stores the Discord webhook configuration securely on the EC2 server.

## Project Highlights

* Automated CI/CD pipeline from GitHub to AWS EC2
* Dockerized FastAPI application
* PostgreSQL containerized using Docker
* Docker Hub used as a container registry
* Shell scripting for deployment and monitoring
* Linux Cron used for scheduled monitoring
* Application health monitoring
* Server resource monitoring
* Discord-based failure notifications
* Non-root application container
* Automated deployment after code changes

## Demo Flow

A simple project demonstration can be performed as follows:

```text
1. Make a code change
       ↓
2. git push
       ↓
3. GitHub Actions starts
       ↓
4. Tests run
       ↓
5. Docker image is built
       ↓
6. Image is pushed to Docker Hub
       ↓
7. EC2 deployment starts
       ↓
8. Application container is restarted
       ↓
9. Health check passes
       ↓
10. Cron continues monitoring
       ↓
11. Simulate a failure
       ↓
12. Discord alert is received
```

## Learning Outcomes

Through this project, I gained practical experience in:

* Linux server management
* Shell scripting
* Git and GitHub workflows
* GitHub Actions CI/CD
* Docker and Docker Compose
* Docker Hub
* AWS EC2 deployment
* PostgreSQL containerization
* Linux Cron automation
* Application and server monitoring
* Webhook-based notifications
* Troubleshooting real deployment issues

## Conclusion

This project demonstrates how a simple application can be transformed into an automated DevOps workflow.

From **code commit to testing, Docker image creation, container registry, cloud deployment, health monitoring, and failure alerts**, the complete process is automated using the DevOps tools and concepts used in this project.
   

