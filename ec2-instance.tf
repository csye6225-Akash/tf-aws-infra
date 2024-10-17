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
