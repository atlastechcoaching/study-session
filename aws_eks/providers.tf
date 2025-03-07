provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"] # location of your creds file once you configure your awscli
  profile                  = "terraform"            # run "aws configure --profile terraform"
}
