


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

variable "cidr_block" {
  description = "CIDR block for the SG"
  type        = string
}

variable "db_name" {
  description = "database name"
  type        = string
}

variable "db_username" {
  description = "database username"
  type        = string
}

variable "owner" {
  description = "owner for ami"
  type        = string
}


variable "domain_name" { default = "akashchhabria.me" }
variable "subdomain" { default = "dev" }  # Can also be "demo"
variable "port" { default = 8080 }  # Replace with your app’s listening port

variable "zone_id" { type = string }  # Replace with your app’s listening port




