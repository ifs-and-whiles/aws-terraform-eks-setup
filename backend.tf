terraform {
  required_version = "~> 0.10"
  backend "s3"{
    bucket                 = "${var.backend_bucket_name}"
    region                 = "${var.region}"
    key                    = "${var.environment_tag}-${var.context_tag}.terraform-state"
    workspace_key_prefix   = "terraform"
    dynamodb_table         = "${var.environment_tag}-${var.context_tag}-terraform-lock"
  }
}