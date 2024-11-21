


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


variable "domain_name" {
  type = string
}
variable "subdomain" {
  type = string
}
variable "port" {
  default = 8080
} # Replace with your app’s listening port

variable "zone_id" {
  type = string
} # Replace with your app’s listening port

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "scale_up_threshold" {
  type = number
}

variable "scale_down_threshold" {
  type = number

}

variable "mailgun_api_key" {
  type = string
}

variable "lambda_package_path" {
  type = string
}

variable "mailgun_domain" {
  type = string
}

variable "BASE_URL" {
  type = string
}

variable "sender_email" {
  type = string
}
