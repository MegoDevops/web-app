terraform {
  backend "s3" {
    bucket = "nti-project-bucket-backend-96d07089"
    key    = "terraform/state/terraform.tfstate"
    region = "eu-west-3"
  }
}