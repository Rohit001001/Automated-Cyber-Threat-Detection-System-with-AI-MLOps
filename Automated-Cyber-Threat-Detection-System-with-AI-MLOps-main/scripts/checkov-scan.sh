#!/bin/bash
# =============================================================================
# Checkov IaC Security Scanner
# =============================================================================
set -e

echo "=========================================="
echo "  Checkov IaC Security Scan"
echo "=========================================="

REPORT_DIR="checkov-reports"
mkdir -p "$REPORT_DIR"

# Scan Terraform
echo "--- Scanning Terraform ---"
checkov -d terraform/ \
    --quiet --compact \
    --output cli \
    --output junitxml \
    --output-file-path "$REPORT_DIR" \
    || echo "Terraform scan completed with findings"

# Scan Helm (render templates first)
echo "--- Scanning Helm templates ---"
helm template test helm/network-security-mlops/ \
    --values helm/network-security-mlops/values-dev.yaml \
    > "$REPORT_DIR/rendered-manifests.yaml" 2>/dev/null || true

if [ -f "$REPORT_DIR/rendered-manifests.yaml" ]; then
    checkov -f "$REPORT_DIR/rendered-manifests.yaml" \
        --framework kubernetes \
        --quiet --compact \
        || echo "Helm scan completed with findings"
fi

echo "=========================================="
echo "  Scan reports saved to: $REPORT_DIR/"
echo "=========================================="
