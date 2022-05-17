output "bucket_name" {
  value = aws_s3_bucket.umcs-bucket.bucket
  description = "the name of the bucket"
}
