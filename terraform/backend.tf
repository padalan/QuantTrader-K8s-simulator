terraform {
  backend "s3" {
    bucket         = "quanttrader-tf-state-183833326510"
    key            = "phase1/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "quanttrader-tf-lock"
    encrypt        = true
  }
}
