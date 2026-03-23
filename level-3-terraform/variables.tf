# Actual values for the variables defined in variables.tf
variable "aws_region" {
  description = "The AWS region to deploy infrastructure into"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (Web Tier)"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (Database/Cache Tier)"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance size"
  type        = string
}

variable "ssh_key_name" {
  description = "The name of the AWS Key Pair for SSH access"
  type        = string
}