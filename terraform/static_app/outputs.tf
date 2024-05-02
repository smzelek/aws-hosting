output "certificate_link" {
  value = "https://console.aws.amazon.com/acm/home#/certificates/${split("certificate/", aws_acm_certificate.default.id)[1]}"
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.default.domain_name
}
