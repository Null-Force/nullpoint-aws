# Main Terraform configuration

resource "aws_s3_bucket" "test" {
  bucket = "nullpoint-test-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}