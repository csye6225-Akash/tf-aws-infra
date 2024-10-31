
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
              # Create the /opt/webapp directory if it doesn't exist
              # mkdir -p /opt/webapp
              # cd /opt/webapp
              # sudo npm install
              cd /opt/webapp && sudo npm install && sudo rm -r .git

              
              if ! id -u csye6225 >/dev/null 2>&1; then
              sudo useradd -m -s /bin/bash csye6225
              fi

              

              # Unzip the webapp.zip file to /opt/webapp directory
              # unzip /opt/webapp/webapp.zip -d /opt/webapp
              sudo chown -R csye6225:csye6225 /opt/webapp
              sudo chmod g+x /opt/webapp
              
              sudo rm -f /opt/webapp/.env  # Delete the existing .env file if it exists
              
              # Remove the ":3306" from the RDS endpoint
              DB_HOST_CLEAN=$(echo ${aws_db_instance.db_instance.endpoint} | sed 's/:3306//')
              
              # Create the .env file with the environment variables
              echo "DEVHOST=$DB_HOST_CLEAN" > /opt/webapp/.env
              echo "DEVUSERNAME=${var.db_username}" >> /opt/webapp/.env
              echo "DEVPASSWORD=${var.db_password}" >> /opt/webapp/.env
              echo "DEVDB=${var.db_name}" >> /opt/webapp/.env
              echo "DEVDB=${aws_s3_bucket.private_bucket.bucket}" >> /opt/webapp/.env
              
              # Create systemd service file for the webapp
              echo "[Unit]" > /etc/systemd/system/webapp.service
              echo "Description=My Web Application" >> /etc/systemd/system/webapp.service
              echo "ConditionPathExists=/opt/webapp/.env" >> /etc/systemd/system/webapp.service
              echo "After=network.target" >> /etc/systemd/system/webapp.service
              
              echo "[Service]" >> /etc/systemd/system/webapp.service
              echo "User=csye6225" >> /etc/systemd/system/webapp.service
              echo "Group=csye6225" >> /etc/systemd/system/webapp.service
              echo "WorkingDirectory=/opt/webapp" >> /etc/systemd/system/webapp.service
              echo "ExecStart=/usr/bin/node /opt/webapp/app.js" >> /etc/systemd/system/webapp.service
              echo "Restart=on-failure" >> /etc/systemd/system/webapp.service
              echo "RestartSec=15" >> /etc/systemd/system/webapp.service
              
              echo "[Install]" >> /etc/systemd/system/webapp.service
              echo "WantedBy=multi-user.target" >> /etc/systemd/system/webapp.service

              # Reload systemd to register the new service
              sudo systemctl daemon-reload
              
              # Start and enable the service to run at boot
              sudo systemctl enable webapp.service
              sudo systemctl start webapp.service
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

