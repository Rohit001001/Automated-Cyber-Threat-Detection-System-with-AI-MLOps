# Rollback Procedures

## Argo Rollouts — Canary Rollback

### Automatic Rollback
The AnalysisTemplate automatically aborts the rollout if the HTTP success rate drops below 95%. Argo Rollouts will automatically roll back to the stable version.

### Manual Rollback via CLI
```bash
# Abort an in-progress canary deployment
kubectl argo rollouts abort <rollout-name> -n network-security

# Undo to the previous version
kubectl argo rollouts undo <rollout-name> -n network-security

# Check rollout status
kubectl argo rollouts status <rollout-name> -n network-security
```

### Manual Rollback via Argo CD UI
1. Open Argo CD UI (https://localhost:8443)
2. Navigate to `network-security-mlops` application
3. Click **History and Rollback**
4. Select the previous healthy revision
5. Click **Rollback**

## Argo CD — Git-Based Rollback

Since Git is the source of truth:
```bash
# Revert the image tag commit in Git
git revert <commit-hash>
git push origin main

# Argo CD will automatically sync to the reverted state
```

## Emergency — Direct Kubernetes Rollback
**Use only in emergencies when GitOps is unavailable:**
```bash
# Scale down the problematic deployment
kubectl scale deployment <name> --replicas=0 -n network-security

# Rollback to previous revision
kubectl rollout undo deployment/<name> -n network-security
```

## Terraform Infrastructure Rollback
```bash
# Revert to a previous state
terraform plan -target=<resource>
terraform apply -target=<resource>

# Or restore from state backup
terraform state pull > backup.tfstate
```
