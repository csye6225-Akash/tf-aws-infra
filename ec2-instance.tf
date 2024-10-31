
# Data source to find the most recent Amazon Linux 2 AMI (for example)
data "aws_ami" "latest_ami" {
  most_recent = true
  # owners           = ["self", "886436923776"] 

  filter {
    name   = "name"
    values = ["csye6225-ami-*"] # Replace this with your required AMI pattern
  }

  owners = ["self", var.owner]
}



resource "aws_instance" "web_app_instances" {
  ami                         = data.aws_ami.latest_ami.id # Replace with your AMI ID
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  subnet_id                   = aws_subnet.public_subnets[0].id
  associate_public_ip_address = "true"

  user_data = <<-EOF
              #!/bin/bash
             
              
              sudo rm -f /opt/webapp/.env  # Delete the existing .env file if it exists
              
              # Remove the ":3306" from the RDS endpoint
              DB_HOST_CLEAN=$(echo ${aws_db_instance.db_instance.endpoint} | sed 's/:3306//')
              
              # Create the .env file with the environment variables
              echo "DEVHOST=$DB_HOST_CLEAN" > /opt/webapp/.env
              echo "DEVUSERNAME=${var.db_username}" >> /opt/webapp/.env
              echo "DEVPASSWORD=${var.db_password}" >> /opt/webapp/.env
              echo "DEVDB=${var.db_name}" >> /opt/webapp/.env
              echo "S3_BUCKET_NAME=${aws_s3_bucket.private_bucket.bucket}" >> /opt/webapp/.env

              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
              -a fetch-config \
              -m ec2 \
              -c file:/opt/webapp/amazon-cloudwatch-agent.json \
              -s      
              
             
EOF





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

