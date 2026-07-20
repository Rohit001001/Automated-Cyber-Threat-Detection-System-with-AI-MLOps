# Monitoring Responsibilities

## Prometheus + Grafana (Application & Cluster Level)

| Metric | Description |
|--------|-------------|
| Pod CPU/Memory usage | Per-pod resource consumption |
| Pod restart count | Container crash detection |
| HTTP request rate | Requests per second to FastAPI |
| HTTP error rate | 4xx/5xx response ratio |
| Request latency | P50/P95/P99 response times |
| Pod availability | Running vs desired replicas |
| HPA scaling events | Autoscaler activity |
| Argo Rollouts progress | Canary promotion status |

**Access**: `kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80`

## AWS CloudWatch (Infrastructure Level)

| Metric | Description |
|--------|-------------|
| EKS control plane logs | API server, audit, authenticator |
| Node CPU/Memory | EC2 instance-level metrics |
| EKS node health | Instance status checks |
| NAT Gateway traffic | Network throughput |
| S3 bucket metrics | Storage usage, request counts |
| ECR image scan results | Vulnerability findings |
| CloudWatch alarms | CPU > 80%, Memory > 80% |

**Access**: AWS Console → CloudWatch → Dashboards

## Why Two Systems?

- **Prometheus/Grafana**: Real-time application observability, custom dashboards, Kubernetes-native metrics, Argo Rollouts analysis
- **CloudWatch**: AWS infrastructure monitoring, EKS control plane logs, billing integration, AWS-native alerting

They complement each other — Prometheus handles app/K8s metrics; CloudWatch handles AWS infra.
