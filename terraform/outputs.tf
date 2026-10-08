output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Elastic IP of the server"
  value       = aws_eip.web.public_ip
}

output "ssh_command" {
  description = "SSH command"
  value       = "ssh -i ~/.ssh/nexvion-key ubuntu@${aws_eip.web.public_ip}"
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.web.public_ip}"
}
