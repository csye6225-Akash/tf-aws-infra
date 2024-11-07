
# Data source to find the most recent Amazon Linux 2 AMI (for example)
data "aws_ami" "latest_ami" {
  most_recent = true


  filter {
    name   = "name"
    values = ["csye6225-ami-*"] # Replace this with your required AMI pattern
  }

  owners = ["self", var.owner]
}

