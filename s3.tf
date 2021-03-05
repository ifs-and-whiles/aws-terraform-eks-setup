resource "aws_s3_bucket" "bucket" {
  bucket = "${var.environment_tag}.${var.context_tag}.${var.s3_bucket_name}"
  acl    = "private"

  tags = {
    environment = var.environment_tag,
    context = var.context_tag,
    Name = "${var.environment_tag}-${var.context_tag}-${var.s3_bucket_name}"
 }
}