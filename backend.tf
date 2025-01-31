terraform {
  backend "s3" {
    bucket = "my-terraform-backend"
    key    = "path/to/my/key"
    region = "us-east-1"
  }
}
