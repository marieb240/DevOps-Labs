provider "aws" {
  region = "eu-north-1"
}

module "repo" {
  source = "github.com/brikis98/devops-book//ch3/tofu/modules/ecr-repo"

  name = "sample-app"
}
