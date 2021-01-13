
resource "aws_launch_configuration" "launch_configuration" {
  name_prefix          = "${var.cluster_name}-"
  image_id             = var.ami_id
  iam_instance_profile = var.iam_instance_profile
  security_groups      = [var.security_group_id]
  instance_type        = var.instance_type

  user_data = var.user_data

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                      = var.cluster_name
  min_size                  = var.cluster_min_size
  max_size                  = var.cluster_max_size
  desired_capacity          = var.desired_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"

  launch_configuration = aws_launch_configuration.launch_configuration.name

  vpc_zone_identifier = var.vpc_zone_identifier

  lifecycle {
    create_before_destroy = true
  }
}