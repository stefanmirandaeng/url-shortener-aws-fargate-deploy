locals {
  name   = "url-shortener"
  region = "ap-southeast-2"

  tags = {
    Project     = "url-shortener"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}