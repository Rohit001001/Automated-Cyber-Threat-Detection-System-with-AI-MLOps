# --- CloudWatch Module ---

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 30
  tags              = { Name = "${var.project_name}-${var.environment}-eks-logs" }
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/eks/${var.eks_cluster_name}/application"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-${var.environment}-app-logs" }
}

# --- CloudWatch Alarms ---
resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS node CPU utilization exceeds 80%"

  dimensions = {
    ClusterName = var.eks_cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "node_memory_high" {
  alarm_name          = "${var.project_name}-${var.environment}-node-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS node memory utilization exceeds 80%"

  dimensions = {
    ClusterName = var.eks_cluster_name
  }
}
