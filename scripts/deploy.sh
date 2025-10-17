#!/bin/bash

# AWS EKS Cluster Deployment Script
# This script deploys the EKS cluster and nginx application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform"
K8S_DIR="k8s"
CLUSTER_NAME="faraway-eks-cluster"
AWS_REGION="us-east-1"

echo -e "${GREEN}Starting AWS EKS Cluster Deployment${NC}"
echo "================================================"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed. Please install it first.${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"

# Deploy infrastructure with Terraform
echo -e "${YELLOW}Deploying infrastructure with Terraform...${NC}"
cd $TERRAFORM_DIR

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan deployment
echo "Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply deployment
echo "Applying Terraform deployment..."
terraform apply tfplan

echo -e "${GREEN}✓ Infrastructure deployed successfully${NC}"

# Get cluster endpoint and configure kubectl
echo -e "${YELLOW}Configuring kubectl...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

echo -e "${GREEN}✓ kubectl configured${NC}"

# Wait for cluster to be ready
echo -e "${YELLOW}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo -e "${GREEN}✓ Cluster is ready${NC}"

# Deploy Kubernetes applications
echo -e "${YELLOW}Deploying Kubernetes applications...${NC}"
cd ../$K8S_DIR

# Deploy metrics server
echo "Deploying metrics server..."
kubectl apply -f metrics-server.yaml

# Wait for metrics server to be ready
echo "Waiting for metrics server to be ready..."
kubectl wait --for=condition=Available deployment/metrics-server -n kube-system --timeout=300s

# Deploy cluster autoscaler
echo "Deploying cluster autoscaler..."
kubectl apply -f cluster-autoscaler.yaml

# Deploy nginx application
echo "Deploying nginx application..."
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
kubectl apply -f nginx-hpa.yaml

# Wait for nginx deployment to be ready
echo "Waiting for nginx deployment to be ready..."
kubectl wait --for=condition=Available deployment/nginx-deployment --timeout=300s

echo -e "${GREEN}✓ All applications deployed successfully${NC}"

# Get service information
echo -e "${YELLOW}Getting service information...${NC}"
echo "================================================"

# Get LoadBalancer endpoint
EXTERNAL_IP=$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -z "$EXTERNAL_IP" ]; then
    EXTERNAL_IP=$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
fi

if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${GREEN}✓ Nginx is accessible at: http://$EXTERNAL_IP${NC}"
else
    echo -e "${YELLOW}⚠ LoadBalancer is still provisioning. Check status with:${NC}"
    echo "kubectl get service nginx-service"
fi

# Show cluster information
echo ""
echo "Cluster Information:"
echo "==================="
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo "Nodes:"
kubectl get nodes
echo ""
echo "Pods:"
kubectl get pods
echo ""
echo "Services:"
kubectl get services

echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo ""
echo "Useful commands:"
echo "==============="
echo "View pods: kubectl get pods"
echo "View services: kubectl get services"
echo "View HPA: kubectl get hpa"
echo "View nodes: kubectl get nodes"
echo "Check cluster autoscaler logs: kubectl logs -n kube-system deployment/cluster-autoscaler"
echo "Scale nginx manually: kubectl scale deployment nginx-deployment --replicas=5"
echo ""
echo "To clean up resources, run: ./scripts/cleanup.sh"
