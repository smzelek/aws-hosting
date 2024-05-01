output "certificate_link" {
  value = "https://console.aws.amazon.com/acm/home#/certificates/${split("certificate/", aws_acm_certificate.default.id)[1]}"
}

output "secrets_link" {
  value = "https://console.aws.amazon.com/secretsmanager/secret?name=${aws_secretsmanager_secret.secrets.name}"
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.default.domain_name
}
