# ---------------------------------------------------------------------------
# Risk 1 – Development S3 Bucket Publicly Accessible
#
# Applies the same S3 Block Public Access configuration to the development
# bucket as is applied to the production bucket.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "dev" {
  bucket = "megger-account-management-system-dev-s3"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "dev" {
  bucket = "megger-account-management-system-dev-s3"

  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  depends_on = [aws_s3_bucket_public_access_block.dev]
}
