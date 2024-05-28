output "haproxy_domain" {
  value = aws_eip.haproxy_ip.public_dns
}
