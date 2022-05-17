output "ec2_instance_public_ip" {
  description = "Public IP address of EC2 instance"
  value       = aws_instance.ec2_ssh_example.public_ip
}
