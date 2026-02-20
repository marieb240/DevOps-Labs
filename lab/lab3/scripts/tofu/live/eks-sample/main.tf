provider "aws" {
  region = "eu-north-1"
}

module "cluster" {
  source = "github.com/marieb240/DevOps-Labs.git//lab/lab3/scripts/tofu/modules/asg"

  name        = "eks-sample"        
  eks_version = "1.29"              

  instance_type        = "t3.micro" 
  min_worker_nodes     = 1          
  max_worker_nodes     = 10         
  desired_worker_nodes = 3          
}
