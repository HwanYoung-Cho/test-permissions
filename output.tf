# Outputs file
output "instance_name" {
  value = aws_instance.tfdemo.id
}

output "instance_ip" {
  value = aws_eip.tfdemo.public_ip
}
