data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_oidc_repo_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
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

  # Allow the admin role to assume this role
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:sts::590184101838:assumed-role/AWSReservedSSO_AdministratorAccess_9350880fda180525/kerukion-smzelek"] # Replace AdminRole with the ARN or role name of the admin
    }

    effect = "Allow"
  }
}


resource "aws_iam_role" "github_role" {
  name               = "${local.fq_app_name}-github-role"
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
          "s3:ListBucket",
          "s3:GetObject",
        ],
        Resource = ["${aws_s3_bucket.default.arn}/*"]
      },
    ]
  })
}

resource "aws_iam_role_policy" "github_role_policy_parent_access" {
  count        = var.subdomain_of != "" ? 1 : 0
  role = aws_iam_role.github_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
        ],
        Resource = [
          "${data.aws_s3_bucket.parent_bucket[0].arn}",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
        ],
        Resource = [
          "${data.aws_s3_bucket.parent_bucket[0].arn}/files/*"
        ]
      },
    ]
  })
}
