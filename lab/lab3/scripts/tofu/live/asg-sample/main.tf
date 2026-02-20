provider "aws" {
  region = "eu-north-1"
}

module "asg" {
  source = "github.com/brikis98/devops-book//ch3/tofu/modules/asg"

  name = "sample-app-asg"                                   

  # TODO: fill in with your own AMI ID!
  ami_id        = "ami-0836abe45b78b6960"                   
  user_data     = filebase64("${path.module}/user-data.sh") 
  app_http_port = 8080                                      

  instance_type    = "t3.micro"                             
  min_size         = 1                                      
  max_size         = 10                                     
  desired_capacity = 3                                      

  target_group_arns = [module.alb.target_group_arn]

  instance_refresh = {
    min_healthy_percentage = 100  
    max_healthy_percentage = 200  
    auto_rollback          = true 
  }
}

module "alb" {
  source = "github.com/brikis98/devops-book//ch3/tofu/modules/alb"

  name                  = "sample-app-alb" 
  alb_http_port         = 80               
  app_http_port         = 8080             
  app_health_check_path = "/"              
}
