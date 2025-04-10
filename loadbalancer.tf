# Load Balancer Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for the application load balancer"
  vpc_id      = aws_vpc.main.id

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "web-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.subnets_public[*].id
}

# Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "${var.vpc_name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

data "aws_acm_certificate" "ssl_certificate" {
  domain   = "${var.aws_profile}.${var.domain_name}"
  statuses = ["ISSUED"]
}

# Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  # port              = 80
  # protocol          = "HTTP"

  port     = 443
  protocol = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.ssl_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


resource "aws_launch_template" "webapp_lt" {
  name          = "webapp-lt"
  image_id      = data.aws_ami.webapp_ami.id
  instance_type = var.instance_type

  key_name = aws_key_pair.webapp_key.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(templatefile("${path.module}/userData.tpl", {
    DB_NAME          = aws_db_instance.rds_instance.db_name
    DB_USER          = aws_db_instance.rds_instance.username
    DB_PASSWORD      = aws_db_instance.rds_instance.password
    DB_HOST          = aws_db_instance.rds_instance.address
    DB_PORT          = 3306
    DB_DIALECT       = "mysql"
    DB_FORCE_CHANGES = false
    S3_BUCKET_NAME   = aws_s3_bucket.webapp_bucket.bucket
    AWS_REGION       = var.aws_region
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 25
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ec2_kms.arn
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.vpc_name}-instance"
    }
  }
}


# Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-auto-scaling-group"
  min_size            = 3
  max_size            = 5
  desired_capacity    = 3
  vpc_zone_identifier = aws_subnet.subnets_public[*].id
  target_group_arns   = [aws_lb_target_group.web_tg.arn]
  launch_template {
    id      = aws_launch_template.webapp_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Environment"
    value               = var.aws_profile
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "CSYE-6225-WebApp"
    propagate_at_launch = true
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                    = "scale-up"
  scaling_adjustment      = 1
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  autoscaling_group_name  = aws_autoscaling_group.web_asg.name
  metric_aggregation_type = "Average"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                    = "scale-down"
  scaling_adjustment      = -1
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  autoscaling_group_name  = aws_autoscaling_group.web_asg.name
  metric_aggregation_type = "Average"
}


# Scale Up Alarm - CPU > 9.5%
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "web-asg-scale-up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 9.5
  alarm_description   = "Scale up if CPU > 9.5%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}

# Scale Down Alarm - CPU < 6.2%
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "web-asg-scale-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 6.2
  alarm_description   = "Scale down if CPU < 6.2%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}

data "aws_route53_zone" "primary" {
  name = "${var.aws_profile}.${var.domain_name}"
}

# Route 53 Record
resource "aws_route53_record" "web_dns" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = data.aws_route53_zone.primary.name
  type    = "A"
  alias {
    name                   = aws_lb.web_alb.dns_name
    zone_id                = aws_lb.web_alb.zone_id
    evaluate_target_health = true
  }
}