terraform {
  backend "s3" {
    bucket      = "kd-hard-to-heat-homes-s3"
    key         = "hard-to-heat-homes-2.0/terraform.tfstate"
    region      = "eu-west-2"
    dynamodb_table = "kd-h2h-state-table"
    encrypt     = true
  }
}