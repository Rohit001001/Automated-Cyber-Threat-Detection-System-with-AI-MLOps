# --- Security Groups Module ---

resource "aws_security_group" "eks" {
  name_prefix = "${var.project_name}-${var.environment}-eks-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS cluster and nodes"

  ingress {
    description = "Allow HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow node communication"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-eks-sg" }

  lifecycle { create_before_destroy = true }
}
