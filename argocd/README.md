# Argo CD Setup Guide

## Prerequisites
- Running EKS cluster (provisioned via Terraform)
- `kubectl` configured for the cluster
- Helm 3 installed

## Install Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Install Argo Rollouts

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

## Access Argo CD UI

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8443:443
# Visit: https://localhost:8443 (user: admin)
```

## Deploy Application

```bash
# Apply project and application
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application.yaml
```

## GitOps Workflow

1. Developer pushes code → GitHub
2. Jenkins CI runs (tests, scans, Docker build, ECR push)
3. Jenkins updates `helm/network-security-mlops/values.yaml` with new image tag
4. Argo CD detects Git change → syncs to EKS
5. If rollouts enabled: Canary deployment (10%→25%→50%→100%)

## Rollback

```bash
# Via Argo CD CLI
argocd app rollback network-security-mlops

# Via Argo Rollouts
kubectl argo rollouts undo <rollout-name> -n network-security

# Via Argo CD UI
# Navigate to application → History → select previous revision → Rollback
```
