# 🏗️ Garden Web App - Complete CI/CD & Infrastructure on AWS

## 📋 Project Overview

A complete **CI/CD pipeline and cloud infrastructure** project deploying the [garden-io/web-app-example](https://github.com/garden-io/web-app-example) to AWS using modern DevOps practices. This project demonstrates a full-stack application with automated infrastructure, container orchestration, and continuous deployment.

## 🏛️ Architecture

### Infrastructure Components

| Zone | Components | Purpose |
|------|------------|---------|
| **Developer Zone** | GitHub, Developer Laptop | Source code management and development |
| **CI/CD Zone** | Jenkins, SonarQube, Trivy | Continuous integration and security scanning |
| **Artifact Zone** | ECR, S3, Secrets Manager, AWS Backup | Secure artifact storage and management |
| **Deployment Zone** | EKS, RDS PostgreSQL, Helm | Container orchestration and database |
| **Monitoring Zone** | Prometheus, Grafana, CloudWatch | Observability and monitoring |

### Technology Stack

- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible
- **Containerization**: Docker, Docker Compose
- **Orchestration**: Kubernetes (EKS)
- **CI/CD**: Jenkins, SonarQube, Trivy
- **Monitoring**: Prometheus, Grafana, CloudWatch
- **Database**: PostgreSQL (RDS)
- **Caching**: Redis
- **Cloud Provider**: AWS

## 📁 Project Structure
nti-project/
├── terraform/ # Infrastructure as Code
│ ├── main.tf # Main Terraform configuration
│ ├── variables.tf # Variable definitions
│ ├── outputs.tf # Output values
│ └── modules/ # Reusable Terraform modules
│ ├── networking/ # VPC, subnets, routing
│ ├── eks/ # EKS cluster configuration
│ ├── ec2/ # Jenkins EC2 instance
│ ├── ecr/ # Container repositories
│ └── s3/ # S3 buckets for logs and state
├── ansible/ # Configuration Management
│ ├── playbook.yml # Main Ansible playbook
│ ├── inventory.ini # Dynamic inventory
│ └── roles/
│ ├── jenkins/ # Jenkins installation & configuration
│ └── cloudwatch/ # CloudWatch agent setup
├── kubernetes/ # Kubernetes manifests
│ ├── base/ # Base Kubernetes resources
│ │ ├── namespace.yaml
│ │ ├── web/ # Frontend deployment & service
│ │ ├── api/ # Backend deployment & service
│ │ ├── postgres/ # Database statefulset
│ │ ├── redis/ # Redis deployment
│ │ └── network-policies/ # Security policies
│ └── helm/ # Helm charts (future use)
├── web-app-example/ # Application source code
│ ├── web/ # React frontend
│ ├── api/ # Node.js backend
│ └── docker-compose.yml # Local development
└── ssh-keys/ # Automatically generated SSH keys

