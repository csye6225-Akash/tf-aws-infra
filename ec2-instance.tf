
# Data source to find the most recent Amazon Linux 2 AMI (for example)
data "aws_ami" "latest_ami" {
  most_recent      = true
  # owners           = ["self", "886436923776"] 

  filter {
    name   = "name"
    values = ["csye6225-ami*-*"] # Replace this with your required AMI pattern
  }

  owners = ["self", "886436923776"] 
}

resource "aws_instance" "web_app_instances" {
  ami           = data.aws_ami.latest_ami.id # Use the dynamically fetched AMI ID
  instance_type = "t2.micro"

resource "aws_instance" "web_app_instances" {
  ami           = "ami-0035747b85a09457c" # Replace with your AMI ID
  instance_type = "t2.micro"
  # security_groups = [aws_security_group.web_sg.name]

  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  subnet_id                   = aws_subnet.public_subnets[0].id
  associate_public_ip_address = "true"





  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name = "web-app-instance"
  }
}




# resource "aws_instance" "web_app_instances" {
#   ami           = "ami-069f2bdaa3443a46d" # Replace with your AMI ID
#   instance_type = "t2.micro"
#   # security_groups = [aws_security_group.web_sg.name]
#   vpc_security_group_ids      = [aws_security_group.web_sg.id]
#   subnet_id                   = aws_subnet.public_subnets[0].id
#   associate_public_ip_address = "true"


#   root_block_device {
#     volume_size           = 25
#     volume_type           = "gp2"
#     delete_on_termination = true
#   }

#   tags = {
#     Name = "web-app-instance"
#   }
# }
