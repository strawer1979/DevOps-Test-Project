# ShopSimple CI/CD Pipeline Documentation

This directory contains the Harness CI/CD pipeline definitions for the ShopSimple project.

## Pipeline Structure

### 1. Infrastructure Pipeline (`infra-pipeline.yaml`)

Deploys Terraform infrastructure for all environments.

**Stages:**
- **Validate** - Runs `terraform fmt -check`, `terraform validate`, and `tflint` to ensure infrastructure code quality
- **Plan** - Generates Terraform plan and saves it as an artifact for review
- **Approval** - Manual approval gate for staging and production environments
- **Apply** - Executes `terraform apply` with the saved plan
- **Verify** - Runs smoke tests to verify infrastructure outputs (S3, RDS, EKS)

**Parameters:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `environment` | Target environment (dev/staging/prod) | dev |
| `region` | AWS region for infrastructure | us-east-1 |
| `action` | Terraform action (plan/apply/destroy) | plan |
| `tf_state_bucket` | S3 bucket for Terraform state | shopsimple-tf-state |

### 2. Service Pipeline (`service-pipeline.yaml`)

CI/CD pipeline for ShopSimple services (frontend, API, worker).

**Stages:**
- **Build** - Builds Docker images for all services using buildx for multi-arch support
- **Test** - Runs unit tests and linting (eslint, prettier)
- **Security Scan** - Scans Docker images with Trivy for vulnerabilities
- **Push** - Pushes images to ECR
- **Deploy to Dev** - Deploys to development environment
- **Deploy to Test** - Deploys to test environment and runs integration tests
- **Deploy to Perf** - Deploys to performance testing environment
- **Deploy to Staging** - Deploys to staging with manual approval
- **Deploy to Prod** - Deploys to production with canary deployment (25% -> 50% -> 100%)

**Parameters:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `environment` | Target environment (dev/test/perf/staging/prod) | dev |
| `image_tag` | Docker image tag (git SHA) | <+GITHUB_SHA> |
| `service` | Service to build (all/frontend/api/worker) | all |
| `ecr_repo_base` | ECR repository base name | shopsimple |
| `aws_region` | AWS region | us-east-1 |

## How to Trigger Pipelines

### Via Harness UI

1. Navigate to the Harness project
2. Select the pipeline (Infra or Service)
3. Click "Run Pipeline"
4. Fill in the required parameters
5. Click "Run"

### Via API

```bash
curl -X POST "https://app.harness.io/pipeline/api/pipelines/execute" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "pipelineIdentifier": "shopsimple_infra_pipeline",
    "variables": [
      {"name": "environment", "value": "staging"},
      {"name": "region", "value": "us-east-1"},
      {"name": "action", "value": "apply"}
    ]
  }'
```

### Via GitHub Actions

See `/workspace/ques/pipelines/github-actions/` for GitHub Actions workflows that can trigger Harness pipelines.

## Environment Promotion Flow

The service pipeline follows a promotion flow:

```
Dev -> Test -> Perf -> Staging -> Prod
```

1. **Dev** - Auto-deployed on every commit to main
2. **Test** - Auto-deployed after dev, runs integration tests
3. **Perf** - Auto-deployed after test, runs load tests
4. **Staging** - Requires manual approval
5. **Prod** - Requires manual approval with canary deployment

## Approval Gates

Approval gates are configured for:

- **Staging** - Requires approval from `release-managers` group
- **Production** - Requires approval from both `release-managers` and `security-team` groups
- **Canary 50%** - Requires approval before proceeding from 25% to 50%
- **Canary 100%** - Requires approval before final rollout

Approvals can be granted via:
1. Harness UI - Click "Approve" on the approval step
2. Harness API - Use the approval endpoint
3. Email - Click the approval link in the notification email

## Rollback Procedures

### Automatic Rollback

The pipeline is configured with automatic rollback on failure:
- Infrastructure pipeline rolls back on validation or apply failures
- Service pipeline rolls back on deployment failures during canary stages

### Manual Rollback

To manually rollback:

**For Kubernetes Deployments:**
```bash
# Rollback to previous revision
kubectl rollout undo deployment/frontend -n shopsimple-prod
kubectl rollout undo deployment/api -n shopsimple-prod
kubectl rollout undo deployment/worker -n shopsimple-prod

# Verify rollback
kubectl rollout status deployment/frontend -n shopsimple-prod
```

**For Terraform:**
```bash
# Navigate to infra directory
cd infra

# Rollback to previous state
terraform apply -var-file=environments/<environment>.tfvars -var=environment=<environment> -auto-approve

# Or restore from state file backup
terraform state pull > previous_state.tfstate
terraform state push previous_state.tfstate
```

### Rollback to Previous Image

To rollback to a previous image version:

1. Find the previous image tag:
```bash
aws ecr list-images --repository-name frontend --region us-east-1
```

2. Re-run the pipeline with the previous image tag:
   - In Harness UI, set `image_tag` to the previous SHA
   - Or use the API to trigger with a specific tag

## Security Scanning

All Docker images are scanned using Trivy before deployment:

- Scans for CRITICAL and HIGH severity vulnerabilities
- Fails the pipeline if CRITICAL vulnerabilities are found
- Reports are stored as pipeline artifacts

View scan results in the Security Scan stage of the pipeline execution.

## Notifications

Pipeline notifications are sent to:
- **Infrastructure Pipeline**: ops-team@shopsimple.com
- **Service Pipeline**: devops@shopsimple.com, release-team@shopsimple.com

Notifications include:
- Pipeline start
- Stage completion
- Approval requests
- Pipeline success/failure

## Troubleshooting

### Pipeline Stuck on Approval

1. Check who has approval permissions
2. Verify email notifications are being received
3. Manually approve via API if needed

### Build Failures

1. Check Docker build logs in the Build stage
2. Verify ECR permissions
3. Check for multi-arch build issues

### Deployment Failures

1. Check kubectl apply output
2. Verify Kubernetes cluster connectivity
3. Check image pull secrets
4. Review pod logs: `kubectl logs -n <namespace> <pod-name>`

### Rollback Not Working

1. Check if previous revision exists: `kubectl rollout history deployment/<name> -n <namespace>`
2. Manually apply previous manifests
3. Verify state in Terraform backend

## Best Practices

1. **Always review plans** before approving infrastructure changes
2. **Monitor canary metrics** during production deployments
3. **Keep image tags** for at least 30 days for rollback capability
4. **Test in lower environments** first before promoting to production
5. **Use branch protection** to require PR reviews before merging to main
