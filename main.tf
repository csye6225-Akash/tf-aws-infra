provider "aws" {
  region = var.aws_region
}

# Data source to get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Creating VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Creating Internet Gateway
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
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 1) # Adjusted for unique public CIDRs
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
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + 4) # Adjusted for unique private CIDRs
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

# Creating Private Route Table
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


resource "aws_db_parameter_group" "rds_parameter_group" {
  name        = "custom-rds-parameter-group"
  family      = "mysql8.0"
  description = "Custom parameter group for RDS"

  parameter {
    name  = "max_connections"
    value = "200"
  }


}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id] # Add your private subnets here

  tags = {
    Name = "RDS Subnet Group"
  }
}

variable "db_password" {
  description = "The password for the RDS database instance"
  type        = string
  sensitive   = true
}

resource "aws_db_instance" "db_instance" {
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  engine_version         = "8.0.33"
  kms_key_id             = aws_kms_key.rds_key.arn
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_password.result
   # Store in environment variable or use Terraform secrets
  storage_encrypted      = true
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az               = false
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.rds_parameter_group.name
  skip_final_snapshot    = true
}
