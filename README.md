# ShopSimple — DevOps Test Project

A complete DevOps deliverable demonstrating infrastructure as code, Kubernetes
orchestration, CI/CD pipelines, and documentation as code for a multi-tier
e-commerce application.

## Project Structure

```
.
├── app/                  # Task 0: Multi-tier application
│   ├── frontend/         # React + Vite SPA (Nginx)
│   ├── api/              # Node.js + Express REST API
│   └── worker/           # BullMQ async job processor
├── infra/                # Task 1: Infrastructure as Code
│   ├── terraform/        # AWS: Terraform modules + environment configs
│   └── terraform-alicloud/ # Alicloud: Terraform modules + environment configs
├── k8s/                  # Task 2: Kubernetes manifests (Kustomize)
│   ├── base/             # Base resources
│   ├── components/       # Reusable overlays (cert-manager, monitoring)
│   └── environments/     # Per-env patches (dev/test/perf/staging/prod)
├── pipelines/            # Task 3: CI/CD pipelines
│   ├── harness/          # Harness YAML pipelines
│   └── github-actions/   # GitHub Actions fallback
└── docs/                 # Task 4: Documentation as Code
    ├── diagrams/         # Mermaid diagram sources
    └── runbooks/         # Operational runbooks
```

## Environments

Multi-cloud, multi-region deployment: AWS + Alicloud, with active-passive
failover for perf/staging/prod environments.

| Env       | AWS Regions                      | Alicloud Regions                   | DNS Failover            |
| --------- | -------------------------------- | ---------------------------------- | ----------------------- |
| dev       | us-east-1                        | cn-hangzhou                        | —                       |
| test      | us-east-1                        | cn-hangzhou                        | —                       |
| perf      | us-east-1 + ap-southeast-1       | cn-hangzhou + ap-southeast-1       | Route53 + Alidns        |
| staging   | us-east-1 + ap-southeast-1       | cn-hangzhou + ap-southeast-1       | Route53 + Alidns        |
| prod      | us-east-1 + ap-southeast-1       | cn-hangzhou + ap-southeast-1       | Route53 + Alidns        |

### Multi-Region Components (perf/staging/prod)

Each cloud's secondary region includes:
- **Network**: Full VPC/VSwitch with public subnets
- **Kubernetes**: EKS/ACK cluster (warm standby)
- **Load Balancer**: ALB/SLB (failover target)
- **Container Registry**: ECR/ACR (image replication)
- **Object Storage**: S3/OSS (cross-region replication)
- **DNS**: Route53/Alidns with health check-based failover

### Cloud Provider Mapping

| Component      | AWS                  | Alicloud                  |
| -------------- | -------------------- | ------------------------- |
| VPC            | VPC + Subnets        | VPC + VSwitch             |
| Kubernetes     | EKS                  | ACK (Container Service)   |
| Database       | RDS PostgreSQL       | RDS PostgreSQL            |
| Cache          | ElastiCache Redis    | KVStore for Redis         |
| Object Store   | S3                   | OSS                       |
| Container Reg  | ECR                  | ACR (Container Registry)  |
| Load Balancer  | ALB                  | SLB                       |
| DNS            | Route 53             | Alibaba Cloud DNS         |
| State Backend  | S3 + DynamoDB        | OSS + OTS (Table Store)   |

## Quick Start

```bash
# Local development
cd app
docker compose up --build

# Validate Terraform (AWS)
cd infra/terraform/environments/dev
terraform init && terraform validate

# Validate Terraform (Alicloud)
cd infra/terraform-alicloud/environments/dev
terraform init && terraform validate

# Render Kubernetes manifests
kubectl kustomize k8s/environments/dev
```

## Documentation

- [Architecture](docs/architecture.md)
- [Infrastructure](docs/infrastructure.md)
- [Pipeline](docs/pipeline.md)
- [Environments](docs/environments.md)
- [Deploy Runbook](docs/runbooks/deploy.md)
