variable "aws_region" {
  description = "AWS region for Nexvion infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for AWS resource tags"
  type        = string
  default     = "nexvion"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the Nexvion EC2 instance"
  type        = string
}

variable "public_key_path" {
  description = "Local SSH public key used by the EC2 instance"
  type        = string
  default     = "~/.ssh/nexvion.pub"
}
