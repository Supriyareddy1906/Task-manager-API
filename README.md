# Automated Cloud Deployment & Monitoring Platform

A DevOps project that automates the testing, containerization, deployment, and monitoring of a Task Manager REST API.

The project demonstrates an end-to-end workflow using **GitHub, GitHub Actions, Jenkins, Docker, Docker Hub, AWS EC2, Ansible, Terraform, Shell Scripting, Cron, Prometheus, Grafana, and Discord alerts**.

## Architecture

```text
Developer
    |
    | git push
    v
GitHub Repository
    |
    +----------------------+
    |                      |
    v                      v
GitHub Actions           Jenkins
    |                      |
    v                      v
Run Tests              Run Tests
    |                      |
    v                      v
Build Docker Image     Build Docker Image
    |                      |
    v                      v
Push to Docker Hub     Push to Docker Hub
    |                      |
    +----------+-----------+
               |
               v
           AWS EC2
               |
       +-------+-------+
       |               |
       v               v
    Ansible          Terraform
    Deployment       Infrastructure
                     Management
       |
       v
 Task Manager API
       |
       +----------------+
       |                |
       v                v
   PostgreSQL       Monitoring
                         |
              +----------+----------+
              |          |          |
              v          v          v
          Prometheus   Grafana   Shell Script
                                      |
                                      v
                                    Cron
                                      |
                                      v
                                Discord Alerts
```

## Project Overview

The **Task Manager API** is a simple REST API developed using FastAPI and PostgreSQL.

The main purpose of this project is not just the application itself, but to build an automated DevOps workflow around it.

The platform provides:

* Automated testing using GitHub Actions and Jenkins
* Docker image creation
* Docker Hub image publishing
* Automated deployment to AWS EC2
* Infrastructure management using Terraform
* Server configuration and deployment using Ansible
* PostgreSQL database running in Docker
* Application health monitoring
* CPU, memory, and disk monitoring
* Prometheus and Grafana monitoring
* Scheduled monitoring using Cron
* Discord notifications when failures are detected

## Technologies Used

| Technology | Purpose |
|---|---|
| Linux | Server administration and command-line operations |
| Shell Scripting | Deployment and monitoring automation |
| Git | Version control |
| GitHub | Source code management |
| GitHub Actions | CI/CD automation |
| Jenkins | CI/CD pipeline and automatic deployment |
| Python / FastAPI | REST API application |
| PostgreSQL | Application database |
| Docker | Application and database containers |
| Docker Compose | Managing multiple containers |
| Docker Hub | Container image registry |
| AWS EC2 | Cloud infrastructure |
| Ansible | Server configuration and deployment |
| Terraform | Infrastructure as Code |
| Prometheus | Metrics collection and monitoring |
| Grafana | Monitoring dashboards and visualization |
| Cron | Scheduled monitoring |
| Discord Webhook | Monitoring alerts |

## Application Features

The Task Manager API provides basic CRUD operations for tasks.

### Main Endpoints

| Endpoint | Purpose |
|---|---|
| `GET /health` | Checks application and database health |
| `POST /tasks` | Creates a new task |
| `GET /tasks` | Retrieves all tasks |
| `GET /tasks/{id}` | Retrieves a specific task |
| `PUT /tasks/{id}` | Updates a task |
| `DELETE /tasks/{id}` | Deletes a task |
| `GET /simulate-error` | Simulates an application failure |
| `GET /simulate-slow` | Simulates a slow response |
| `GET /docs` | Opens the FastAPI Swagger documentation |

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
   |
   v
GitHub Actions
   |
   v
Run Python Tests
   |
   v
Build Docker Image
   |
   v
Push Image to Docker Hub
   |
   v
Connect to AWS EC2
   |
   v
Pull Latest Docker Image
   |
   v
Restart Application
   |
   v
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

The CI/CD pipeline connects to the EC2 server through SSH and runs the deployment script.

**5. Health Check**

After deployment, the application health endpoint is checked to verify that the application is running correctly.

## Jenkins Automation

Jenkins is used to automate the build and deployment process.

The Jenkins pipeline performs activities such as:

* Checking out source code from GitHub
* Building the application using Maven where applicable
* Running pipeline stages
* Deploying the application to the Tomcat server
* Supporting automatic builds through Poll SCM

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

## AWS EC2 Deployment

The application is deployed on AWS EC2 instances.

The EC2 infrastructure is used for:

* Running Docker
* Running the FastAPI application
* Running PostgreSQL
* Executing deployment scripts
* Running monitoring services
* Executing Ansible automation

### Security Group Access

```text
22    → SSH
8000  → FastAPI application
9090  → Prometheus
3000  → Grafana
8080  → Jenkins
```

## Ansible Automation

Ansible is used to configure and manage the EC2 infrastructure.

The project uses an Ansible Controller and an Ansible Target.

Ansible automates server configuration and application deployment.

Main activities include:

* Connecting to the target EC2 instance through SSH
* Installing and configuring required packages
* Installing and starting Docker
* Deploying the application
* Managing application services

## Terraform Infrastructure Management

Terraform is used to manage the existing AWS infrastructure using **Infrastructure as Code (IaC)**.

Instead of creating duplicate EC2 instances, the existing Ansible Controller and Ansible Target instances and their security groups were imported into Terraform state.

### AWS Resources Managed

| Resource | Description |
|---|---|
| Ansible Controller | Existing AWS EC2 instance |
| Ansible Target | Existing AWS EC2 instance |
| Controller Security Group | Controls SSH and Jenkins access |
| Target Security Group | Controls SSH, API, Prometheus and Grafana access |

### Terraform Files

| File | Purpose |
|---|---|
| `main.tf` | Security group configuration |
| `ec2.tf` | EC2 instance configuration |
| `variables.tf` | Input variables |
| `terraform.tfvars` | Variable values |
| `outputs.tf` | EC2 instance IDs and public IPs |
| `versions.tf` | Terraform and AWS provider configuration |

### Terraform Workflow

```text
Terraform Configuration
        |
        v
   terraform init
        |
        v
  terraform validate
        |
        v
    terraform fmt
        |
        v
 Import Existing AWS Resources
        |
        v
    terraform plan
        |
        v
    terraform output
```

### Terraform Commands

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Format Terraform files:

```bash
terraform fmt
```

Import existing AWS resources:

```bash
terraform import aws_instance.ansible_target i-06744492b61de6034

terraform import aws_instance.ansible_controller i-03d9fedc23c246dea

terraform import aws_security_group.ansible_controller_sg sg-076c76a9628beec8a

terraform import aws_security_group.ansible_target_sg sg-0c1c36662b14cb6c7
```

Review infrastructure changes:

```bash
terraform plan
```

Display infrastructure outputs:

```bash
terraform output
```

### Terraform Verification

Terraform successfully imported all four existing AWS resources.

The final Terraform plan reported:

```text
No changes. Your infrastructure matches the configuration.
```

The Terraform validation and formatting checks also completed successfully.

This confirms that the Terraform configuration matches the existing AWS infrastructure.

## Docker Hub

The application Docker image is stored in Docker Hub.

```text
supriya9606/task-manager-api
```

The CI/CD pipeline automatically builds and pushes updated images whenever changes are pushed to the main branch.

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

## Prometheus and Grafana Monitoring

Prometheus is used to collect application and system metrics.

Grafana is used to visualize the collected metrics through dashboards.

The monitoring setup helps track:

* Application performance
* CPU usage
* Memory usage
* API response time
* Server metrics

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
        |
        v
    monitor.sh
        |
        +-- Container Check
        +-- Health Check
        +-- CPU Check
        +-- Memory Check
        +-- Disk Check
                |
                v
          Problem Found?
             /     \
           No       Yes
           |         |
           v         v
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
* Jenkins pipeline automation
* Ansible-based server configuration
* Terraform-based infrastructure management
* Infrastructure as Code using Terraform
* Shell scripting for deployment and monitoring
* Linux Cron used for scheduled monitoring
* Application health monitoring
* Prometheus and Grafana dashboards
* Server resource monitoring
* Discord-based failure notifications
* Non-root application container
* Automated deployment after code changes

## Demo Flow

A simple project demonstration can be performed as follows:

```text
1. Make a code change
       |
       v
2. git push
       |
       v
3. CI/CD pipeline starts
       |
       v
4. Tests run
       |
       v
5. Docker image is built
       |
       v
6. Image is pushed to Docker Hub
       |
       v
7. EC2 deployment starts
       |
       v
8. Application container is restarted
       |
       v
9. Health check passes
       |
       v
10. Monitoring continues
       |
       v
11. Simulate a failure
       |
       v
12. Discord alert is received
```

## Learning Outcomes

Through this project, I gained practical experience in:

* Linux server management
* Shell scripting
* Git and GitHub workflows
* GitHub Actions CI/CD
* Jenkins pipeline automation
* Docker and Docker Compose
* Docker Hub
* AWS EC2 deployment
* Ansible automation
* Terraform and Infrastructure as Code
* PostgreSQL containerization
* Prometheus and Grafana monitoring
* Linux Cron automation
* Application and server monitoring
* Webhook-based notifications
* Troubleshooting real deployment issues

## Conclusion

This project demonstrates how a simple application can be transformed into an automated DevOps workflow.

From **code commit to testing, Docker image creation, container registry, cloud deployment, infrastructure management, health monitoring, and failure alerts**, the complete process demonstrates practical DevOps tools and concepts.