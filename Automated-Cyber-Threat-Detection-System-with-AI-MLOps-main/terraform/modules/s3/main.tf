# --- S3 Module ---

resource "aws_s3_bucket" "training" {
  bucket        = "${var.training_bucket_name}-${var.environment}"
  force_destroy = true
  tags          = { Name = "${var.project_name}-training-${var.environment}" }
}

resource "aws_s3_bucket_versioning" "training" {
  bucket = aws_s3_bucket.training.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "training" {
  bucket = aws_s3_bucket.training.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "training" {
  bucket                  = aws_s3_bucket.training.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "prediction" {
  bucket        = "${var.prediction_bucket_name}-${var.environment}"
  force_destroy = true
  tags          = { Name = "${var.project_name}-prediction-${var.environment}" }
}

resource "aws_s3_bucket_versioning" "prediction" {
  bucket = aws_s3_bucket.prediction.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prediction" {
  bucket = aws_s3_bucket.prediction.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "prediction" {
  bucket                  = aws_s3_bucket.prediction.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
