terraform {
  backend "s3" {
    bucket         = "atlastech-state-bucket"       # name of bucket
    key            = "terraform.tfstate"        # path in bucket where your state file will be stored
    region         = "us-east-1"
  }
}