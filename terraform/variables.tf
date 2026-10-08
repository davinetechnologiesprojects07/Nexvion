variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name used for resources"
  type        = string
  default     = "Nexvion"
}

variable "instance_type" {
  description = "EC2 instance type (Free Tier eligible)"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 20
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/nexvion-key.pub"
}

variable "admin_cidr" {
  description = "Your public IP in CIDR form, allowed to use SSH, e.g. 203.0.113.10/32"
  type        = string
}
