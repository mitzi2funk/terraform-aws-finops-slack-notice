terraform {
  backend "s3" {
    key    = "finops.tfstate"
    region = "ap-northeast-1"
  }
}
