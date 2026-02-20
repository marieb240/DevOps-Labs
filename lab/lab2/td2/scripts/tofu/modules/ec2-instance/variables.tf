variable "ami_id" {
  description = "The ID of the AMI to run."
  type        = string
}
variable "name" {
  description = "Name used for tags and resource names"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "port" {
  description = "Port to expose for the sample app"
  type        = number
  default     = 8080
}