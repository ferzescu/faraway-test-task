#!/bin/bash

# AWS EKS Cluster Cleanup Script
# This script removes all resources created by the deployment

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

echo -e "${RED}Starting AWS EKS Cluster Cleanup${NC}"
echo "====================================="

# Confirmation prompt
read -p "Are you sure you want to delete all resources? This action cannot be undone! (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete Kubernetes applications first
echo -e "${YELLOW}Deleting Kubernetes applications...${NC}"
cd $K8S_DIR

# Delete nginx application
echo "Deleting nginx application..."
kubectl delete -f nginx-hpa.yaml --ignore-not-found=true
kubectl delete -f nginx-service.yaml --ignore-not-found=true
kubectl delete -f nginx-deployment.yaml --ignore-not-found=true

# Delete cluster autoscaler
echo "Deleting cluster autoscaler..."
kubectl delete -f cluster-autoscaler.yaml --ignore-not-found=true

# Delete metrics server
echo "Deleting metrics server..."
kubectl delete -f metrics-server.yaml --ignore-not-found=true

echo -e "${GREEN}✓ Kubernetes applications deleted${NC}"

# Wait for LoadBalancer to be deleted
echo -e "${YELLOW}Waiting for LoadBalancer to be deleted...${NC}"
sleep 30

# Delete infrastructure with Terraform
echo -e "${YELLOW}Deleting infrastructure with Terraform...${NC}"
cd ../$TERRAFORM_DIR

# Destroy infrastructure
echo "Destroying Terraform infrastructure..."
terraform destroy -auto-approve

echo -e "${GREEN}✓ Infrastructure destroyed successfully${NC}"

# Clean up local files
echo -e "${YELLOW}Cleaning up local files...${NC}"
rm -f tfplan
rm -f terraform.tfstate*
rm -rf .terraform/
rm -rf .terraform.lock.hcl

echo -e "${GREEN}✓ Local files cleaned up${NC}"

echo ""
echo -e "${GREEN}Cleanup completed successfully!${NC}"
echo ""
echo "All resources have been deleted:"
echo "- EKS cluster and node groups"
echo "- VPC and networking resources"
echo "- Security groups and IAM roles"
echo "- LoadBalancer and associated resources"
echo "- All Kubernetes applications"
echo ""
echo "Note: Some resources may take a few minutes to be fully deleted from AWS."
