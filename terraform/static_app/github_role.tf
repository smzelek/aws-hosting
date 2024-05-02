data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_oidc_repo_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

resource "aws_iam_role" "github_role" {
  name               = "${var.app_name}-github-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_repo_role.json
}

resource "aws_iam_role_policy" "github_role_policy" {
  role = aws_iam_role.github_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
        ],
        Resource = ["${aws_s3_bucket.default.arn}/*"]
      },
    ]
  })
}
