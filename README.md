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
| **Deployment Zone** | EKS, PostgreSQL, Helm | Container orchestration and database |
| **Monitoring Zone** |  CloudWatch |  monitoring |

### Technology Stack

- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible
- **Containerization**: Docker
- **Orchestration**: Kubernetes (EKS), helm
- **CI/CD**: Jenkins, SonarQube, Trivy
- **Monitoring**:  CloudWatch
- **Database**: PostgreSQL 
- **Cloud Provider**: AWS


## 🚀 Implementation Phases

### Phase 1: Terraform Infrastructure ✅

- ✅ VPC with public and private subnets
- ✅ ECR repositories for web and API services
- ✅ S3 buckets for Terraform state and ELB logs
- ✅ NAT Gateways and Internet Gateway
- ✅ IAM roles and security groups

### Phase 2: Ansible Configuration ✅

- ✅ Jenkins server installation and configuration
- ✅ Docker, kubectl, and Helm installation
- ✅ AWS CLI and CloudWatch agent setup
- ✅ Automated SSH key generation and management

### Phase 3: Docker & Local Development ✅

- ✅ Multi-stage Dockerfiles for production
- ✅ Docker Compose for local development
- ✅ Nginx configuration for React app
- ✅ Environment-specific configurations

### Phase 4: Kubernetes Deployment 🟡
- ✅ EKS cluster 
- ✅ Application deployment to EKS

### Phase 5: CI/CD Pipeline & Monitoring 🔲
- ✅ Jenkins multi-branch pipeline
- ✅ SonarQube quality gates
- ✅ Trivy security scanning

## 🛠️ Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform v1.0+
- Ansible v2.9+

### Deployment Steps

1. **Clone and Initialize**
   ```bash
   git clone https://github.com/MegoDevops/web-app.git
   cd web-app/terraform
   terraform init
   cd web-app/ansible
   ansible-playbook -i inventory.ini playbook.yml
   
