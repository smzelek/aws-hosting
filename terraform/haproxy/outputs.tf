output "haproxy_domain" {
  value = aws_eip.haproxy_ip.public_dns
}

output "haproxy_instance_id" {
  value = aws_instance.haproxy.id
}