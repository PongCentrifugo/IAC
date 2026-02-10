# Infrastructure as Code

Infrastructure definitions for provisioning and managing the Pong platform on AWS. This directory contains the complete set of Terraform configurations, Kubernetes manifests, and operational scripts required to deploy and operate the application in a production environment.

## Overview

The infrastructure is split into two layers: cloud resource provisioning with Terraform and workload orchestration with Kubernetes. Terraform manages the lifecycle of all AWS resources. Kubernetes manifests define the application topology, and Flux provides continuous delivery through a GitOps workflow.

## Directory Structure

```
iac/
├── terraform/             Cloud resource definitions (AWS)
│   ├── main.tf            VPC, EKS, ElastiCache, CloudFront, S3, ECR, IAM
│   ├── variables.tf       Input variables and defaults
│   ├── outputs.tf         Exported resource identifiers and endpoints
│   ├── versions.tf        Provider version constraints
│   ├── acm.tf             TLS certificate lookups
│   ├── ebs-csi.tf         EBS CSI driver IRSA configuration
│   ├── vault-kms.tf       KMS keys and IAM for Vault auto-unseal
│   ├── github-oidc.tf     GitHub Actions OIDC federation
│   └── image-reflector-irsa.tf   Flux image reflector ECR access
│
├── kubernetes/
│   ├── flux/              Flux GitOps configuration
│   │   ├── flux-system/   Flux bootstrap components
│   │   ├── infrastructure/   Helm releases and cluster-level resources
│   │   └── apps/          Application Kustomization references
│   │
│   ├── manifests/
│   │   ├── base/          Base Kustomize layer
│   │   │   ├── backend/       Backend API deployment and service
│   │   │   ├── centrifugo/    Centrifugo WebSocket server
│   │   │   └── cloudflared/   Cloudflare Tunnel ingress
│   │   └── overlays/
│   │       └── production/    Production-specific patches
│   │
│   └── apps/
│       └── centrifugo/    Standalone Centrifugo deployment definitions
│
└── scripts/               Operational scripts for Vault lifecycle management
    ├── vault-init-and-configure.sh
    ├── vault-store-secrets.sh
    └── vault-backup.sh
```

## AWS Resources

Terraform provisions the following resources in `eu-south-2`:

| Resource | Purpose |
|---|---|
| VPC | Isolated network with public and private subnets across two availability zones |
| EKS | Managed Kubernetes cluster with a `t3.medium` node group |
| ElastiCache | Single-node Redis 7 instance for Centrifugo message brokering |
| ECR | Container registries for backend and Centrifugo images |
| CloudFront | CDN distribution for the frontend single-page application |
| S3 | Origin bucket for frontend static assets |
| NAT Gateway | Outbound internet access for private subnet workloads |
| KMS | Encryption key for HashiCorp Vault auto-unseal |
| IAM | Roles and policies for EKS, GitHub Actions OIDC, Flux, and Vault |
| Budgets | Monthly cost threshold alerts |

## Kubernetes Workloads

The cluster runs three primary workloads managed through Kustomize with base and production overlay layers:

| Workload | Description |
|---|---|
| Backend | Go API server handling game logic and client authentication |
| Centrifugo | Real-time WebSocket messaging server backed by Redis |
| Cloudflared | Cloudflare Tunnel daemon providing secure ingress without a public load balancer |

## Continuous Delivery

Flux watches this repository and reconciles the cluster state automatically. The pipeline is organized into three layers:

| Layer | Scope |
|---|---|
| flux-system | Core Flux controllers and source definitions |
| infrastructure | Cluster-level dependencies including Vault Agent Injector and image automation controllers |
| apps | Application-level Kustomizations referencing the manifests directory |

Image automation controllers monitor ECR for new container tags pushed by CI and commit manifest updates back to the repository, closing the GitOps loop without manual intervention.

## Scripts

Operational scripts for managing the HashiCorp Vault lifecycle within the cluster.

| Script | Description |
|---|---|
| `vault-init-and-configure.sh` | Initializes the Vault server, generates recovery keys and a root token, enables the Kubernetes authentication method, configures a KV v2 secrets engine, and creates access policies for the application namespace. Intended to run once after initial Vault deployment. |
| `vault-store-secrets.sh` | Generates cryptographically random secrets for Centrifugo and the backend, collects environment-specific values such as the Redis endpoint and Cloudflare tunnel token, and writes all entries to Vault under the `secret/pong/` path. |
| `vault-backup.sh` | Creates a Raft storage snapshot from the running Vault instance, uploads it to an S3 bucket with server-side encryption and versioning enabled, and provides restore instructions. |

## Secrets Management

HashiCorp Vault runs inside the cluster and provides dynamic secret injection into application pods through the Vault Agent sidecar. Vault auto-unseal is configured through an AWS KMS key provisioned by Terraform. Initialization, secret storage, and backup procedures are handled by the scripts in the `scripts/` directory.
