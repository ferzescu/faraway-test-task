# AWS EKS Cluster with Terraform

A complete Infrastructure as Code solution for deploying an AWS EKS cluster with autoscaling capabilities and a publicly accessible nginx application.

## 🚀 Features

- **AWS EKS Cluster** with Kubernetes 1.33
- **Node Autoscaling** (1-3 t3.medium instances)
- **Pod Autoscaling** with Horizontal Pod Autoscaler (HPA)
- **Public LoadBalancer** for nginx application
- **Cost Optimized** for demo/testing (us-east-1, public subnets)
- **Production Ready Checklist** with comprehensive guidelines

## 📁 Project Structure

```
├── terraform/           # Infrastructure as Code
│   ├── providers.tf     # AWS provider configuration
│   ├── versions.tf      # Terraform version constraints
│   ├── variables.tf     # Input variables
│   ├── outputs.tf       # Output values
│   ├── vpc.tf          # VPC and networking
│   └── eks.tf          # EKS cluster configuration
├── k8s/                # Kubernetes manifests
│   ├── nginx-deployment.yaml    # Nginx application
│   ├── nginx-service.yaml       # LoadBalancer service
│   ├── nginx-hpa.yaml          # Horizontal Pod Autoscaler
│   ├── metrics-server.yaml     # Metrics collection
│   └── cluster-autoscaler.yaml # Node autoscaling
├── scripts/            # Automation scripts
│   ├── deploy.sh       # Automated deployment
│   └── cleanup.sh      # Resource cleanup
└── docs/              # Documentation
    ├── DEPLOYMENT.md   # Step-by-step deployment guide
    └── PRODUCTION_READY.md # Production readiness checklist
```

## 🛠 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform 1.0+
- kubectl 1.28+
- AWS account with EKS permissions

### Deploy Everything

```bash
# Clone and navigate to project
git clone <repository-url>
cd faraway-test-task

# Deploy infrastructure and applications
./scripts/deploy.sh
```

### Manual Deployment

```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name faraway-eks-cluster

# 3. Deploy applications
kubectl apply -f k8s/metrics-server.yaml
kubectl apply -f k8s/cluster-autoscaler.yaml
kubectl apply -f k8s/nginx-deployment.yaml
kubectl apply -f k8s/nginx-service.yaml
kubectl apply -f k8s/nginx-hpa.yaml
```

## 🔧 Configuration

### Key Variables (terraform/variables.tf)

- `aws_region`: us-east-1 (cheapest region)
- `cluster_version`: 1.33 (latest stable)
- `node_group_instance_types`: ["t3.medium"] (cost-effective)
- `node_group_min_size`: 1
- `node_group_max_size`: 3
- `node_group_desired_size`: 2

### Nginx Configuration

- **Replicas**: 2 initial, 2-10 with HPA
- **Resources**: 100m CPU, 128Mi memory (requests)
- **Scaling**: CPU threshold 70%, Memory threshold 80%
- **Health Checks**: Liveness and readiness probes

## 📊 Monitoring & Testing

### Check Status

```bash
# View all resources
kubectl get all

# Check HPA status
kubectl get hpa

# View LoadBalancer endpoint
kubectl get service nginx-service
```

### Test Autoscaling

```bash
# Generate load (requires hey tool)
LB_URL=$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
hey -n 10000 -c 50 http://$LB_URL

# Watch scaling
kubectl get hpa -w
kubectl get pods -w
```

## 💰 Cost Optimization

This setup is optimized for cost with:
- **Region**: us-east-1 (cheapest)
- **Instances**: t3.medium (cost-effective)
- **Networking**: Public subnets only (no NAT Gateway)
- **Node Count**: 1-3 nodes (minimal)

**Estimated monthly cost**: ~$50-100

## 🧹 Cleanup

```bash
# Automated cleanup
./scripts/cleanup.sh

# Manual cleanup
kubectl delete -f k8s/
cd terraform && terraform destroy
```

## 📚 Documentation

- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Comprehensive deployment guide
- **[PRODUCTION_READY.md](docs/PRODUCTION_READY.md)** - Production readiness checklist

## 🔒 Security Notes

⚠️ **This is a demo setup optimized for cost and simplicity**

For production use, see the [Production Readiness Checklist](docs/PRODUCTION_READY.md) which includes:
- Private subnets with NAT Gateway
- Multi-AZ deployment (3+ AZs)
- VPC endpoints for AWS services
- Network policies and security hardening
- Monitoring and logging stack
- Backup and disaster recovery
- CI/CD pipeline integration

## 🏗 Architecture

```
Internet
    ↓
AWS LoadBalancer (ELB)
    ↓
EKS Cluster (us-east-1)
    ├── Node Group (1-3 t3.medium)
    │   ├── nginx Pods (2-10 replicas)
    │   └── HPA (CPU/Memory scaling)
    └── Cluster Autoscaler
        └── Node Scaling (1-3 nodes)
```

## 🆘 Support

For issues and questions:
1. Check the [troubleshooting section](docs/DEPLOYMENT.md#troubleshooting)
2. Review the [production checklist](docs/PRODUCTION_READY.md)
3. Create an issue in the repository

---

**Note**: This is a test task implementation. For production use, please follow the comprehensive guidelines in the production readiness checklist.