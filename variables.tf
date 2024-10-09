


variable "aws_region" {
  description = "AWS region to create resources in"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "project_name" {
  description = "Project name to tag resources"
  type        = string
}
