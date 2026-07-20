# Checkov Exceptions Documentation

## Documented Suppressions

### CKV_AWS_79 — EC2 Instance Metadata Service v2
- **Rule**: Ensure Instance Metadata Service Version 2 (IMDSv2) is enforced
- **Why it occurs**: EKS managed node groups handle IMDS configuration internally
- **Security Impact**: Low — EKS manages node security
- **Remediation**: Enforce via EKS node group launch template if needed

### CKV_K8S_40 — Containers should not run with allowPrivilegeEscalation
- **Status**: FIXED — `allowPrivilegeEscalation: false` is set in containerSecurityContext
- **No suppression needed**

### CKV_K8S_22 — Use read-only filesystem for containers
- **Rule**: Ensure containers use read-only root filesystem
- **Why it occurs**: The FastAPI application writes to `logs/`, `Artifacts/`, `prediction/` directories at runtime
- **Security Impact**: Medium — allows filesystem writes inside container
- **Remediation**: Mount writable directories as emptyDir volumes in production

### CKV2_AWS_19 — S3 bucket encryption with KMS
- **Rule**: Ensure S3 bucket is encrypted with KMS
- **Why it occurs**: We use AES256 (SSE-S3) for cost efficiency
- **Security Impact**: Low — SSE-S3 still encrypts data at rest
- **Remediation**: Switch to `aws:kms` if compliance requires CMK encryption
