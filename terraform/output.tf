
output "nginx_public_ip" {
  value       = aws_instance.nginx.public_ip
  description = "Public IP of Nginx server"
}



#output "private_key_pem" {
#  value       = tls_private_key.deployer.private_key_pem
#  description = "Private SSH key for instance access"
#  sensitive   = true
#}

