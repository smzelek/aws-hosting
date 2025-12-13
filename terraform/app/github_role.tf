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
}

resource "aws_iam_role" "github_role" {
  name               = "${local.fq_app_name}-github-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_repo_role.json
}

resource "aws_iam_role_policy" "github_role_policy" {
  depends_on = [
    aws_ecs_service.service,
    aws_iam_role.task_execution_role,
    aws_iam_role.task_role,
    aws_ecs_service.service,
    aws_ecr_repository.image_repository
  ]
  role = aws_iam_role.github_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
        ],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:TagResource",
          "ecs:RegisterTaskDefinition",
        ],
        Resource = ["${aws_ecs_task_definition.service_task_definition.arn_without_revision}:*"]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",
          "ecs:TagResource",
          "ecs:RegisterTaskDefinition",
        ],
        Resource = ["${aws_ecs_task_definition.command_task_definition.arn_without_revision}:*"]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:FilterLogEvents",
          "logs:StartLiveTail",
          "logs:StopLiveTail",
        ],
        Resource = ["${aws_cloudwatch_log_group.command.arn}:*"]
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          "${aws_iam_role.task_execution_role.arn}",
          "${aws_iam_role.task_role.arn}",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ],
        Resource = [
          "${aws_ecs_service.service.id}"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:DescribeImageScanFindings",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListTagsForResource",
          "ecr:UploadLayerPart",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:GetLifecyclePolicy"
        ],
        Resource = [
          "${aws_ecr_repository.image_repository.arn}"
        ]
      },
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
