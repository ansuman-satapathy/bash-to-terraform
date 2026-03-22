output "web_public_ip" {
  description = "Public IP of Web Server"
  value       = aws_instance.web.public_ip
}

output "db_private_ip" {
  description = "Private IP of DB Server"
  value       = aws_instance.db.private_ip
}

output "cache_private_ip" {
  description = "Private IP of Cache Server"
  value       = aws_instance.cache.private_ip
}