terraform {
  backend "s3" {
    bucket         = "url-shortener-tfstate-447170313597"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}