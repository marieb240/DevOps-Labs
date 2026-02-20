provider "aws" {
  region = "eu-north-1"
}

variable "instances" {
  type = map(object({
    name          = string
    instance_type = string
    port          = number
  }))
}

# Instantiate module per entry in the instances map
module "sample_app" {
  source = "github.com/marieb240/DevOps-Labs.git//lab/lab2/td2/scripts/tofu/modules/ec2-instance""
  for_each = var.instances

  name          = each.value.name
  instance_type = each.value.instance_type
  port          = each.value.port
  ami_id        = var.ami_id
}

output "public_ip" {
  value = aws_instance.sample_app.public_ip
}

variable "ami_id" { type = string }