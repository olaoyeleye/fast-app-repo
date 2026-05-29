terraform {
  backend "s3" {
    bucket  = "fast-api-app-sirkay"
    key     = "fast-api-app-statefile/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true

  }
}
