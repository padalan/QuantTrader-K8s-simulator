provider "aws" {
  region  = "us-west-2"
  profile = "quanttrader-dev"

  default_tags {
    tags = {
      Project     = "quanttrader-k8s"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
} 