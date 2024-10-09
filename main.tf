# main.tf

provider "aws" {
  region = var.aws_region
}

# Data source to get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Creating vpc
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Creating IG
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Creating Public Subnets 
resource "aws_subnet" "public_subnets" {
  count                   = min(3, length(data.aws_availability_zones.available.names))
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 1)  # This may need adjusting
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# Creating Private Subnets 
resource "aws_subnet" "private_subnets" {
  count             = min(3, length(data.aws_availability_zones.available.names))
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + 4)  # Adjusted index for private subnets
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# Creating Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-route-table"
  }
}

# Associating public subnets with the public route table
resource "aws_route_table_association" "public_subnet_associations" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Creating Private RT
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-private-route-table"
  }
}

# Associating private subnets with the private route table
resource "aws_route_table_association" "private_subnet_associations" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
