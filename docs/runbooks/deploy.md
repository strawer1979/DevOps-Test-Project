# Deployment Runbook

This runbook provides step-by-step procedures for deploying ShopSimple
across all environments on **both AWS and Alibaba Cloud (Alicloud)**.

---

## Prerequisites

### Required Tools

- `kubectl` (v1.29+)
- `terraform` (v1.5+)
- `docker` (v24+)
- `kustomize` (built into kubectl)
- **AWS**: `aws-cli` (v2.x)
- **Alicloud**: `aliyun-cli` (v3.x)

### Required Access

**AWS:**
- AWS IAM credentials with appropriate permissions
- Kubernetes cluster access (via `aws eks update-kubeconfig`)
- ECR push permissions
- Terraform state access (S3 + DynamoDB)

**Alicloud:**
- Alicloud AccessKey ID/Secret (or RAM role)
- Kubernetes cluster access (via `aliyun cs` commands)
- ACR push permissions
- Terraform state access (OSS + OTS)

---

## Infrastructure Deployment

### Initial Setup (First Time Only)

1. **Create Terraform State Backend**:
   ```bash
   cd infra/terraform/global/remote-state
   terraform init
   terraform apply
   ```

2. **Verify State Bucket**:
   ```bash
   aws s3 ls s3://shopsimple-terraform-state
   ```

### Deploy Environment

#### Step 1: Select Environment

```bash
ENV=dev  # or test, perf, staging, prod
cd infra/terraform/environments/$ENV
```

#### Step 2: Initialize Terraform

```bash
terraform init
```

**Expected Output**:
```
Terraform has been successfully initialized!
```

#### Step 3: Plan Changes

```bash
terraform plan -out=tfplan
```

**Review the plan**:
- Resources to be created
- Resources to be modified
- Resources to be destroyed

**For staging/prod**: Share plan with approvers.

#### Step 4: Apply Changes

```bash
terraform apply tfplan
```

**Expected Duration**:
- dev/test: 10-15 minutes
- perf/staging: 20-30 minutes
- prod: 30-45 minutes

#### Step 5: Verify Deployment

```bash
# Check outputs
terraform output

# Verify EKS cluster
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name)
kubectl cluster-info

# Verify RDS
terraform output -raw rds_endpoint

# Verify ALB
terraform output -raw alb_dns_name
curl -I http://$(terraform output -raw alb_dns_name)/health
```

### Update Environment

```bash
cd infra/terraform/environments/$ENV
terraform init
terraform plan -out=tfplan
# Review plan
terraform apply tfplan
```

### Destroy Environment

⚠️ **WARNING**: This will delete all resources!

```bash
cd infra/terraform/environments/$ENV
terraform plan -destroy -out=tfplan
# Review carefully
terraform apply tfplan
```

**For prod**: Requires manual confirmation + approval.

---

## Application Deployment

### Build Images

```bash
cd app

# Build all services
docker compose build

# Or build individually
docker build -t shopsimple/api:latest ./api
docker build -t shopsimple/frontend:latest ./frontend
docker build -t shopsimple/worker:latest ./worker
```

### Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin {account_id}.dkr.ecr.us-east-1.amazonaws.com

# Tag images
GIT_SHA=$(git rev-parse --short HEAD)
docker tag shopsimple/api:latest {account_id}.dkr.ecr.us-east-1.amazonaws.com/shopsimple/api:$GIT_SHA
docker tag shopsimple/frontend:latest {account_id}.dkr.ecr.us-east-1.amazonaws.com/shopsimple/frontend:$GIT_SHA
docker tag shopsimple/worker:latest {account_id}.dkr.ecr.us-east-1.amazonaws.com/shopsimple/worker:$GIT_SHA

# Push images
docker push {account_id}.dkr.ecr.us-east-1.amazonaws.com/shopsimple/api:$GIT_SHA
docker push {account_id}.dkr.ecr.us-east-1.amazonaws.com/shopsimple/frontend:$GIT_SHA
docker push {account_id}.dkr.ecr.us-east-1.amazonaws.com/shopsimple/worker:$GIT_SHA
```

### Deploy to Kubernetes

#### Step 1: Update Kustomize Images

```bash
ENV=dev  # or test, perf, staging, prod
GIT_SHA=$(git rev-parse --short HEAD)
ECR_URI={account_id}.dkr.ecr.us-east-1.amazonaws.com

cd k8s/environments/$ENV

kustomize edit set image \
  shopsimple/api=$ECR_URI/shopsimple/api:$GIT_SHA \
  shopsimple/frontend=$ECR_URI/shopsimple/frontend:$GIT_SHA \
  shopsimple/worker=$ECR_URI/shopsimple/worker:$GIT_SHA
```

#### Step 2: Configure Kubernetes Context

```bash
aws eks update-kubeconfig --name shopsimple-$ENV --region us-east-1
kubectl config current-context
```

#### Step 3: Apply Manifests

```bash
kubectl apply -k k8s/environments/$ENV
```

**Expected Output**:
```
namespace/shopsimple-dev configured
serviceaccount/shopsimple-api configured
...
deployment.apps/api configured
deployment.apps/frontend configured
deployment.apps/worker configured
```

#### Step 4: Monitor Rollout

```bash
# Watch rollout status
kubectl rollout status deployment/api -n shopsimple-$ENV --timeout=300s
kubectl rollout status deployment/frontend -n shopsimple-$ENV --timeout=300s
kubectl rollout status deployment/worker -n shopsimple-$ENV --timeout=300s
```

#### Step 5: Verify Deployment

```bash
# Check pods
kubectl get pods -n shopsimple-$ENV

# Check services
kubectl get svc -n shopsimple-$ENV

# Check ingress
kubectl get ingress -n shopsimple-$ENV

# Health check
curl -f https://$ENV.shopsimple.example.com/health
curl -f https://$ENV.shopsimple.example.com/api/health
```

---

## Alicloud Deployment

### Infrastructure Deployment (Alicloud)

#### Step 1: Select Environment

```bash
ENV=dev  # or test, perf, staging, prod
cd infra/terraform-alicloud/environments/$ENV
```

#### Step 2: Initialize Terraform

```bash
terraform init
```

The backend uses OSS bucket `shopsimple-terraform-state-alicloud` with
OTS (Table Store) locking.

#### Step 3: Plan Changes

```bash
terraform plan -out=tfplan
```

#### Step 4: Apply Changes

```bash
terraform apply tfplan
```

**Expected Duration**:
- dev/test: 10-15 minutes
- perf/staging: 20-30 minutes
- prod: 30-45 minutes

#### Step 5: Verify Deployment

```bash
# Check outputs
terraform output

# Get ACK kubeconfig
aliyun cs DescribeClusterUserKubeconfig --ClusterId $(terraform output -raw ack_cluster_id) > ~/.kube/acksimple-$ENV

# Verify cluster
KUBECONFIG=~/.kube/acksimple-$ENV kubectl cluster-info

# Verify SLB
terraform output -raw slb_address
curl -I http://$(terraform output -raw slb_address)/health
```

### Application Deployment (Alicloud)

#### Push to ACR

```bash
# Login to ACR
docker login --username=<your-username> registry.cn-hangzhou.aliyuncs.com

# Tag images
GIT_SHA=$(git rev-parse --short HEAD)
REGISTRY=registry.cn-hangzhou.aliyuncs.com/shopsimple

docker tag shopsimple/api:latest $REGISTRY/api:$GIT_SHA
docker tag shopsimple/frontend:latest $REGISTRY/frontend:$GIT_SHA
docker tag shopsimple/worker:latest $REGISTRY/worker:$GIT_SHA

# Push images
docker push $REGISTRY/api:$GIT_SHA
docker push $REGISTRY/frontend:$GIT_SHA
docker push $REGISTRY/worker:$GIT_SHA
```

#### Deploy to ACK

```bash
# Get ACK kubeconfig
ENV=dev
CLUSTER_ID=$(cd infra/terraform-alicloud/environments/$ENV && terraform output -raw ack_cluster_id)
aliyun cs DescribeClusterUserKubeconfig --ClusterId $CLUSTER_ID > ~/.kube/acksimple-$ENV
export KUBECONFIG=~/.kube/acksimple-$ENV

# Update Kustomize image tags
cd k8s/environments/$ENV
kustomize edit set image \
  shopsimple/api=registry.cn-hangzhou.aliyuncs.com/shopsimple/api:$GIT_SHA \
  shopsimple/frontend=registry.cn-hangzhou.aliyuncs.com/shopsimple/frontend:$GIT_SHA \
  shopsimple/worker=registry.cn-hangzhou.aliyuncs.com/shopsimple/worker:$GIT_SHA

# Apply manifests
kubectl apply -k k8s/environments/$ENV

# Monitor rollout
kubectl rollout status deployment/api -n shopsimple-$ENV --timeout=300s
kubectl rollout status deployment/frontend -n shopsimple-$ENV --timeout=300s
kubectl rollout status deployment/worker -n shopsimple-$ENV --timeout=300s
```

### Alicloud-Specific Troubleshooting

#### ACK Node Issues

```bash
# Check node status
kubectl get nodes -o wide

# Check node events
kubectl describe node <node-name>

# Check ACK cluster status
aliyun cs DescribeClusterDetail --ClusterId $CLUSTER_ID
```

#### SLB Issues

```bash
# Check SLB status
aliyun slb DescribeLoadBalancerAttribute --LoadBalancerId <slb-id>

# Check VServer groups
aliyun slb DescribeVServerGroups --LoadBalancerId <slb-id>

# Check listeners
aliyun slb DescribeLoadBalancerListeners --LoadBalancerId <slb-id>
```

#### OSS Issues

```bash
# Check bucket
aliyun oss stat oss://<bucket-name>

# List objects
aliyun oss ls oss://<bucket-name>
```

---

## Rollback Procedures

### Application Rollback

#### Rollback to Previous Version

```bash
# Check rollout history
kubectl rollout history deployment/api -n shopsimple-$ENV

# Rollback to previous revision
kubectl rollout undo deployment/api -n shopsimple-$ENV

# Or rollback to specific revision
kubectl rollout undo deployment/api -n shopsimple-$ENV --to-revision=2

# Verify rollback
kubectl rollout status deployment/api -n shopsimple-$ENV
```

#### Rollback via Kustomize

```bash
# Revert kustomization.yaml to previous image tag
git checkout HEAD~1 -- k8s/environments/$ENV/kustomization.yaml

# Re-apply
kubectl apply -k k8s/environments/$ENV
```

### Infrastructure Rollback

#### Using Terraform State

```bash
cd infra/terraform/environments/$ENV

# List state versions
aws s3 ls s3://shopsimple-terraform-state/$ENV/

# Download previous state
aws s3 cp s3://shopsimple-terraform-state/$ENV/terraform.tfstate.{version_id} terraform.tfstate

# Plan to revert
terraform plan -out=tfplan

# Apply to revert
terraform apply tfplan
```

#### Emergency Infrastructure Rollback

If Terraform is broken:
1. Manually fix resources via AWS Console (temporary)
2. Import resources back into Terraform state
3. Run `terraform plan` to verify state matches reality

---

## Canary Deployment (Production Only)

### Deploy Canary

```bash
# Apply Argo Rollout manifest
kubectl apply -f k8s/environments/prod/rollout-api.yaml

# Watch canary progress
kubectl argo rollouts get rollout api -n shopsimple-prod --watch
```

### Promote Canary

```bash
# Manual promotion (if auto-promotion disabled)
kubectl argo rollouts promote api -n shopsimple-prod
```

### Abort Canary

```bash
# Abort and rollback
kubectl argo rollouts abort api -n shopsimple-prod

# Undo rollout
kubectl argo rollouts undo api -n shopsimple-prod
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n shopsimple-$ENV

# Check events
kubectl get events -n shopsimple-$ENV --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n shopsimple-$ENV
kubectl logs <pod-name> -n shopsimple-$ENV --previous  # crashed pod
```

**Common Issues**:
- ImagePullBackOff: Check image tag, ECR permissions
- CrashLoopBackOff: Check application logs, health checks
- Pending: Check node resources, pod limits

### Database Connection Issues

```bash
# Test connectivity from pod
kubectl exec -it <api-pod> -n shopsimple-$ENV -- \
  psql $DATABASE_URL -c "SELECT 1"

# Check RDS status
aws rds describe-db-instances --db-instance-identifier shopsimple-$ENV-db
```

### High Latency

```bash
# Check HPA
kubectl get hpa -n shopsimple-$ENV

# Check pod resources
kubectl top pods -n shopsimple-$ENV

# Check node resources
kubectl top nodes
```

### Ingress Not Working

```bash
# Check ingress
kubectl describe ingress api -n shopsimple-$ENV

# Check ALB ingress controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check target groups in AWS Console
```

---

## Post-Deployment Checklist

### After Every Deployment

- [ ] All pods are Running and Ready
- [ ] Health checks pass (`/health` endpoints)
- [ ] Logs show no errors
- [ ] Metrics are normal (CPU, memory, latency)
- [ ] Ingress is accessible
- [ ] Database connections are healthy
- [ ] Redis connections are healthy
- [ ] No failed jobs in worker queue

### After Production Deployment

- [ ] Monitor for 15 minutes
- [ ] Check error rates (CloudWatch, application logs)
- [ ] Verify canary metrics (if applicable)
- [ ] Update deployment documentation
- [ ] Notify stakeholders
- [ ] Archive deployment record

---

## Emergency Contacts

| Role                  | Contact              | Escalation         |
| --------------------- | -------------------- | ------------------ |
| DevOps On-Call        | PagerDuty            | DevOps Manager     |
| Engineering Lead      | Slack @eng-lead      | VP Engineering     |
| Database Admin        | Slack @dba-team      | Infrastructure Dir |
| Security Team         | security@example.com | CISO               |

---

## Runbook Maintenance

This runbook should be:
- Reviewed quarterly
- Updated after every major incident
- Tested via game days (quarterly)
- Version controlled (this document)

**Last Updated**: 2026-08-01
**Last Reviewed By**: DevOps Team
