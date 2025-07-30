
# Create a unique S3 bucket
resource "aws_s3_bucket" "my_test_bucket" {
  # Bucket names must be globally unique.
  # Change "s3-buk-test-12345" to your unique name if needed.
  bucket = "s3-buk-test-12345"

  tags = {
    Name        = "My test bucket"
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}
