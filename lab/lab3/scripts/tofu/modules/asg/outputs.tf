output "security_group_id" {
  description = "Security group ID for the ASG instances"
  value       = aws_security_group.sample_app.id
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.sample_app.id
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.sample_app.name
}