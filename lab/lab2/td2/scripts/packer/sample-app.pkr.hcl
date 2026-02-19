packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amazon_linux" {
  ami_name        = "sample-app-packer-${uuidv4()}"
  ami_description = "Amazon Linux 2 AMI with a Node.js sample app."
  instance_type   = "t3.micro"
  region          = "eu-north-1"
  source_ami      = "ami-02781fbdc79017564"
  ssh_username    = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.amazon_linux"]

  provisioner "file" {
    source      = "app.js"
    destination = "/home/ec2-user/app.js"
  }

    provisioner "shell" {
    inline = [
      "sudo chown ec2-user:ec2-user /home/ec2-user/app.js",
      "sudo chmod 755 /home/ec2-user/app.js",
      "echo 'App copied. Node installation skipped on purpose (AMI variability).' | sudo tee /home/ec2-user/packer-note.txt"
    ]
  }
}
