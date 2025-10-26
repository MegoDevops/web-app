#!/bin/bash
set -e

echo "Deploying application to EKS..."

cd /mnt/e/nti-project/kubernetes

# Apply all Kubernetes manifests
kubectl apply -f base/namespace.yaml
kubectl apply -f base/postgres/
kubectl apply -f base/redis/
kubectl apply -f base/api/
kubectl apply -f base/web/

# Wait for services to be ready
echo "Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n garden-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n garden-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=api -n garden-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=web -n garden-app --timeout=300s

# Get the web service LoadBalancer URL
echo "Getting LoadBalancer URL..."
kubectl get service web -n garden-app

echo "Deployment completed successfully!"