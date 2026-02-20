provider "aws" {
  region = "eu-north-1"
}

variable "ami_id" {
  type = string
}

variable "instances" {
  type = map(object({
    name          = string
    instance_type = string
    port          = number
  }))

  default = {
    app1 = { name = "sample-app-1", instance_type = "t3.micro", port = 8080 }
    app2 = { name = "sample-app-2", instance_type = "t3.micro", port = 8080 }
  }
}

module "sample_app" {
  source   = "github.com/marieb240/DevOps-Labs.git//lab/lab2/td2/scripts/tofu/modules/ec2-instance"
  for_each = var.instances

  name          = each.value.name
  instance_type = each.value.instance_type
  port          = each.value.port
  ami_id        = var.ami_id
}

output "public_ips" {
  value = [for m in values(module.sample_app) : m.public_ip]
}