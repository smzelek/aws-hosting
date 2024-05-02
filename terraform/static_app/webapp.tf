resource "aws_s3_bucket" "default" {
  bucket        = local.fq_app_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_access" {
  depends_on = [aws_s3_bucket_public_access_block.default]
  bucket     = aws_s3_bucket.default.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*"
        Action    = ["s3:GetObject"],
        Resource  = ["${aws_s3_bucket.default.arn}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "default" {
  bucket = aws_s3_bucket.default.bucket
  error_document {
    key = "index.html"
  }
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "default" {
  bucket = aws_s3_bucket.default.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

resource "aws_cloudfront_distribution" "default" {
  aliases             = local.is_subdomain ? ["${var.app_domain}.${var.subdomain_of}"] : [var.app_domain, "www.${var.app_domain}"]
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  staging             = false
  wait_for_deployment = false

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.disabled.id
    compress               = true
    target_origin_id       = aws_s3_bucket_website_configuration.default.website_endpoint
    viewer_protocol_policy = "allow-all"
  }

  origin {
    connection_attempts = 3
    connection_timeout  = 10
    domain_name         = aws_s3_bucket_website_configuration.default.website_endpoint
    origin_id           = aws_s3_bucket_website_configuration.default.website_endpoint
    origin_path         = ""

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.default.certificate_arn
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }
}

data "aws_acm_certificate" "subdomain_of" {
  count  = local.is_subdomain ? 1 : 0
  domain = var.subdomain_of
}

resource "aws_acm_certificate" "default" {
  count                     = local.is_subdomain ? 0 : 1
  domain_name               = var.app_domain
  key_algorithm             = "RSA_2048"
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.app_domain}"]
}

# Must go handle DNS validation manually
resource "aws_acm_certificate_validation" "default" {
  certificate_arn = local.is_subdomain ? data.aws_acm_certificate.subdomain_of[0].arn : aws_acm_certificate.default[0].arn
}
