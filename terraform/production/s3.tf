# ---------------------------------------------------------------------------
# Risk 1 – Production S3 Bucket Publicly Accessible
#
# Enables S3 Block Public Access on the production bucket so that no public
# ACL or bucket policy can expose objects to the internet.  All four block
# flags are set to true to cover every avenue for public exposure.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "prod" {
  bucket = "megger-account-management-system-prod-s3"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Remove any existing bucket ACL by setting it to private
resource "aws_s3_bucket_ownership_controls" "prod" {
  bucket = "megger-account-management-system-prod-s3"

  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  depends_on = [aws_s3_bucket_public_access_block.prod]
}
