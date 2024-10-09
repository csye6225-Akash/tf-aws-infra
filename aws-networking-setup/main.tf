# main.tf

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create 3 Public Subnets
resource "aws_subnet" "public_subnets" {
  count                   = 1
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

