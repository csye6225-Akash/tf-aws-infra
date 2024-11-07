resource "aws_launch_template" "csye6225_lt" {
  name          = "csye6225_lt"
  image_id      = data.aws_ami.latest_ami.id
  instance_type = "t2.micro"
  //key_name      = "YOUR_AWS_KEYNAME"

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<-EOF
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
  )

}



# Repeat for other required policies


resource "aws_autoscaling_group" "csye6225_asg" {
  desired_capacity = var.desired_capacity
  max_size         = var.max_size
  min_size         = var.min_size
  launch_template {
    id      = aws_launch_template.csye6225_lt.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id] # Add your subnets
  target_group_arns   = [aws_lb_target_group.csye6225_tg.arn]

  tag {
    key                 = "Name"
    value               = "csye6225-asg-instance"
    propagate_at_launch = true
  }
  health_check_grace_period = 300
  health_check_type         = "EC2"
}

# Auto-scaling policies
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                    = "scale_up_policy"
  scaling_adjustment      = 1
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  autoscaling_group_name  = aws_autoscaling_group.csye6225_asg.name
  metric_aggregation_type = "Average"
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                    = "scale_down_policy"
  scaling_adjustment      = -1
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  autoscaling_group_name  = aws_autoscaling_group.csye6225_asg.name
  metric_aggregation_type = "Average"
}


resource "aws_lb" "csye6225_alb" {
  name               = "csye6225-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id] # Add your subnets

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "csye6225_tg" {
  name        = "csye6225tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/healthz"
    port                = 8080
    protocol            = "HTTP"
    timeout             = 20
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "csye6225_http_listener" {
  load_balancer_arn = aws_lb.csye6225_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.csye6225_tg.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_up_threshold # Adjust this threshold as needed
  alarm_description   = "Triggers scale-up policy when CPU utilization exceeds given threshold."

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.csye6225_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale-down-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_down_threshold # Adjust this threshold as needed
  alarm_description   = "Triggers scale-down policy when CPU utilization falls below given threshold"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.csye6225_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]
}

