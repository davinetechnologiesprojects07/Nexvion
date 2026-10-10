output "instance_id" {
  value = aws_instance.nexvion.id
}

output "public_ip" {
  value = aws_instance.nexvion.public_ip
}

output "public_dns" {
  value = aws_instance.nexvion.public_dns
}

output "vpc_id" {
  value = aws_vpc.nexvion.id
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/nexvion ec2-user@${aws_instance.nexvion.public_ip}"
}
