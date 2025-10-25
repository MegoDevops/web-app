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

---

## 🧩 Technologies Used

- **Terraform** – AWS infrastructure provisioning (VPC, EKS, EC2, S3, etc.)
- **Ansible** – Server configuration and automation
- **Kubernetes** – Application deployment and scaling
- **Docker** – Containerization for backend and frontend
- **Jenkins** – CI/CD pipeline automation
- **Helm** (optional) – For templating and managing Kubernetes manifests

---

## 🚀 Future Enhancements

- Add Helm charts for application deployment
- Integrate Prometheus + Grafana for monitoring
- Configure GitHub Actions for automated CI/CD
- Secure secrets using AWS Secrets Manager
