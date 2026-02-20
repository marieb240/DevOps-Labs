provider "aws" {
  region = "eu-north-1"
}

module "repo" {
  source = "github.com/marieb240/DevOps-Labs.git//lab/lab3/scripts/tofu/modules/ecr-repo"

  name = "sample-app"
}
