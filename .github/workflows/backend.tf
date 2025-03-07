terraform {
  backend "s3" {
    bucket         = "atlastech-state-bucket"       # name of bucket
    key            = "state/terraform.tfstate"        # path in bucket where your state file will be stored
    region         = "us-east-1"
    profile        = "terraform"
    dynamodb_table = "terraform-state-locking"        # name of dynamodb table for state lock
  }
}