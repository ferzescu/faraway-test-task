# AWS EKS Cluster Deployment Guide

This guide provides step-by-step instructions for deploying an AWS EKS cluster with autoscaling capabilities and a publicly accessible nginx application.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Manual Deployment](#manual-deployment)
- [Verification](#verification)
- [Testing Autoscaling](#testing-autoscaling)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## Prerequisites

Before starting, ensure you have the following tools installed and configured:

### Required Tools

1. **AWS CLI** (v2.x)
   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Verify installation
   aws --version
   ```

2. **Terraform** (v1.0+)
   ```bash
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Verify installation
   terraform --version
   ```

3. **kubectl** (v1.28+)
   ```bash
   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   
   # Verify installation
   kubectl version --client
   ```

### AWS Configuration

1. **Configure AWS credentials:**
   ```bash
   aws configure
   ```
   Enter your:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region: `us-east-1`
   - Default output format: `json`

2. **Verify AWS access:**
   ```bash
   aws sts get-caller-identity
   ```

3. **Required AWS permissions:**
   - EC2 (VPC, Security Groups, Instances)
   - EKS (Cluster management)
   - IAM (Role creation and management)
   - Auto Scaling (Node group management)

## Quick Start

For a quick deployment, use the automated script:

```bash
# Make scripts executable (if not already done)
chmod +x scripts/*.sh

# Deploy everything
./scripts/deploy.sh
```

The script will:
1. Check prerequisites
2. Deploy infrastructure with Terraform
3. Configure kubectl
4. Deploy Kubernetes applications
5. Display service endpoints

## Manual Deployment

### Step 1: Deploy Infrastructure

1. **Navigate to terraform directory:**
   ```bash
   cd terraform
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review the deployment plan:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```
   Type `yes` when prompted.

5. **Note the outputs:**
   ```bash
   terraform output
   ```

### Step 2: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name faraway-eks-cluster

# Verify cluster access
kubectl get nodes
```

### Step 3: Deploy Kubernetes Applications

1. **Deploy metrics server:**
   ```bash
   kubectl apply -f k8s/metrics-server.yaml
   ```

2. **Deploy cluster autoscaler:**
   ```bash
   kubectl apply -f k8s/cluster-autoscaler.yaml
   ```

3. **Deploy nginx application:**
   ```bash
   kubectl apply -f k8s/nginx-deployment.yaml
   kubectl apply -f k8s/nginx-service.yaml
   kubectl apply -f k8s/nginx-hpa.yaml
   ```

## Verification

### Check Cluster Status

```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods

# Check services
kubectl get services

# Check HPA
kubectl get hpa
```

### Verify LoadBalancer

```bash
# Get LoadBalancer endpoint
kubectl get service nginx-service

# Test nginx (replace with your LoadBalancer URL)
curl http://<LOADBALANCER-URL>
```

### Check Autoscaling Components

```bash
# Check cluster autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler

# Check metrics server
kubectl get pods -n kube-system | grep metrics-server

# Check HPA status
kubectl describe hpa nginx-hpa
```

## Testing Autoscaling

### Test Pod Autoscaling (HPA)

1. **Generate load on nginx:**
   ```bash
   # Install hey (load testing tool)
   go install github.com/rakyll/hey@latest
   
   # Get LoadBalancer URL
   LB_URL=$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
   
   # Generate load
   hey -n 10000 -c 50 http://$LB_URL
   ```

2. **Monitor scaling:**
   ```bash
   # Watch HPA
   kubectl get hpa -w
   
   # Watch pods
   kubectl get pods -w
   ```

### Test Node Autoscaling

1. **Scale up nginx deployment:**
   ```bash
   kubectl scale deployment nginx-deployment --replicas=10
   ```

2. **Monitor node scaling:**
   ```bash
   # Watch nodes
   kubectl get nodes -w
   
   # Check cluster autoscaler logs
   kubectl logs -n kube-system deployment/cluster-autoscaler -f
   ```

## Monitoring

### Useful Commands

```bash
# View all resources
kubectl get all

# View cluster info
kubectl cluster-info

# View node details
kubectl describe nodes

# View pod details
kubectl describe pods

# View service details
kubectl describe service nginx-service

# View HPA details
kubectl describe hpa nginx-hpa
```

### Resource Monitoring

```bash
# Top nodes
kubectl top nodes

# Top pods
kubectl top pods

# Resource usage by namespace
kubectl top pods --all-namespaces
```

## Troubleshooting

### Common Issues

1. **LoadBalancer not getting external IP:**
   ```bash
   # Check service status
   kubectl describe service nginx-service
   
   # Check AWS LoadBalancer in console
   aws elbv2 describe-load-balancers --region us-east-1
   ```

2. **Pods not starting:**
   ```bash
   # Check pod events
   kubectl describe pod <pod-name>
   
   # Check logs
   kubectl logs <pod-name>
   ```

3. **HPA not working:**
   ```bash
   # Check metrics server
   kubectl get pods -n kube-system | grep metrics-server
   
   # Check HPA events
   kubectl describe hpa nginx-hpa
   ```

4. **Cluster autoscaler not working:**
   ```bash
   # Check logs
   kubectl logs -n kube-system deployment/cluster-autoscaler
   
   # Check IAM permissions
   aws iam get-role --role-name faraway-eks-cluster-node-group-role
   ```

### Debug Commands

```bash
# Check cluster status
kubectl get componentstatuses

# Check API server
kubectl get --raw /healthz

# Check node conditions
kubectl get nodes -o wide

# Check pod resource requests
kubectl describe pods | grep -A 5 "Requests:"
```

## Cleanup

### Automated Cleanup

```bash
./scripts/cleanup.sh
```

### Manual Cleanup

1. **Delete Kubernetes applications:**
   ```bash
   kubectl delete -f k8s/nginx-hpa.yaml
   kubectl delete -f k8s/nginx-service.yaml
   kubectl delete -f k8s/nginx-deployment.yaml
   kubectl delete -f k8s/cluster-autoscaler.yaml
   kubectl delete -f k8s/metrics-server.yaml
   ```

2. **Destroy infrastructure:**
   ```bash
   cd terraform
   terraform destroy
   ```

3. **Clean up local files:**
   ```bash
   rm -f terraform/tfplan
   rm -f terraform/terraform.tfstate*
   rm -rf terraform/.terraform/
   ```

## Cost Optimization

This deployment is optimized for cost with:
- **Region:** us-east-1 (cheapest)
- **Instance type:** t3.medium (cost-effective)
- **Node count:** 1-3 nodes (minimal)
- **No NAT Gateway:** Uses public subnets only
- **Public endpoints:** No private endpoint costs

**Estimated monthly cost:** ~$50-100 (depending on usage)

## Security Notes

- This is a demo setup with public endpoints
- For production, see `PRODUCTION_READY.md`
- Always use private subnets and NAT Gateway in production
- Implement proper network policies and security groups
- Use AWS Secrets Manager for sensitive data

## Next Steps

After successful deployment:
1. Review the production readiness checklist
2. Implement monitoring and logging
3. Set up CI/CD pipelines
4. Configure backup and disaster recovery
5. Implement security hardening

For production deployment guidelines, see `PRODUCTION_READY.md`.
