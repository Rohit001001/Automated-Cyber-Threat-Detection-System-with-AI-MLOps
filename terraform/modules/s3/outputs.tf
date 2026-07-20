output "training_bucket_name"   { value = aws_s3_bucket.training.id }
output "prediction_bucket_name" { value = aws_s3_bucket.prediction.id }
