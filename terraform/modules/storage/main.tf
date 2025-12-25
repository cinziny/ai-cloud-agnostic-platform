variable "cloud" {}
variable "tags" {}

resource "aws_s3_bucket" "bucket" {
  count  = var.cloud == "aws" ? 1 : 0
  bucket = "ai-platform-dev"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "versioning" {
  count  = var.cloud == "aws" ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

output "storage_id" {
  value = var.cloud == "aws" ? aws_s3_bucket.bucket[0].id : null
}
