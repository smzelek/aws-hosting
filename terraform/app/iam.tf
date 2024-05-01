data "aws_iam_policy_document" "ecs_task_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# IAM Task Execution Role
resource "aws_iam_role" "task_execution_role" {
  name               = "${var.app_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy_attachment" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "task_execution_role_secret_policy" {
  role = aws_iam_role.task_execution_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          "${aws_secretsmanager_secret.secrets.arn}"
        ]
      }
    ]
  })
}

# IAM Task Role
resource "aws_iam_role" "task_role" {
  name               = "${var.app_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_policy.arn
}

# unused
resource "aws_iam_policy" "task_role_policy" {
  name = "${var.app_name}-task-role-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
        ]
        Resource = ["*"]
      },
    ]
  })
}
