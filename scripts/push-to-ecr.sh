#!/bin/bash
set -e

echo "Building and pushing Docker images to ECR..."

cd /mnt/e/nti-project/web-app-example

# Get ECR repository URLs from Terraform output
cd /mnt/e/nti-project/terraform
ECR_WEB_URL=$(terraform output -raw ecr_web_repository_url)
ECR_API_URL=$(terraform output -raw ecr_api_repository_url)

cd /mnt/e/nti-project/web-app-example

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin $ECR_WEB_URL

# Build Docker images
echo "Building Docker images..."
docker build -t garden-web-app-web:latest ./web
docker build -t garden-web-app-api:latest ./api

# Tag and push web image
echo "Pushing web image to ECR..."
docker tag garden-web-app-web:latest $ECR_WEB_URL:latest
docker push $ECR_WEB_URL:latest

# Tag and push api image  
echo "Pushing API image to ECR..."
docker tag garden-web-app-api:latest $ECR_API_URL:latest
docker push $ECR_API_URL:latest

echo "Docker images pushed to ECR successfully!"
echo "Web: $ECR_WEB_URL"
echo "API: $ECR_API_URL"