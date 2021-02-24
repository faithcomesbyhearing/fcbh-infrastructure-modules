resource "aws_iam_role" "iam_task" {
  assume_role_policy = data.aws_iam_policy_document.iam_assume_ecs.json
}

resource "aws_iam_role" "iam_execution" {
  assume_role_policy = data.aws_iam_policy_document.iam_assume_ecs.json
}

resource "aws_iam_role" "iam_authenticated" {
  assume_role_policy = data.aws_iam_policy_document.iam_assume_authenticated.json
}

data "aws_iam_policy_document" "iam_assume_ecs" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "iam_assume_authenticated" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.cognito.id]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "iam_task" {
  role       = aws_iam_role.iam_task.name
  policy_arn = aws_iam_policy.iam_task.arn
}

resource "aws_iam_policy" "iam_task" {
  policy = data.aws_iam_policy_document.iam_task.json
}

data "aws_iam_policy_document" "iam_task" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.s3_upload.arn]
  }

  statement {
    actions = ["s3:*Object"]
    resources = [
      "${aws_s3_bucket.s3_upload.arn}/*",
      "arn:aws:s3:::${var.s3_artifacts_bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "iam_execution" {
  role       = aws_iam_role.iam_execution.name
  policy_arn = aws_iam_policy.iam_execution.arn
}

resource "aws_iam_policy" "iam_execution" {
  policy = data.aws_iam_policy_document.iam_execution.json
}

data "aws_iam_policy_document" "iam_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.main.arn}:*"]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [aws_ecr_repository.main.arn]
  }
}

resource "aws_iam_role_policy_attachment" "iam_authenticated" {
  role       = aws_iam_role.iam_authenticated.name
  policy_arn = aws_iam_policy.iam_authenticated.arn
}

resource "aws_iam_policy" "iam_authenticated" {
  policy = data.aws_iam_policy_document.iam_authenticated.json
}

data "aws_iam_policy_document" "iam_authenticated" {
  statement {
    actions   = ["ecs:RunTask"]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.main.family}"]
  }

  statement {
    actions   = ["ecs:DescribeTasks"]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/${aws_ecs_cluster.main.name}/*"]
  }

  statement {
    actions   = ["logs:GetLogEvents"]
    resources = ["${aws_cloudwatch_log_group.main.arn}:*"]
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.iam_execution.arn, aws_iam_role.iam_task.arn]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    actions   = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["${aws_s3_bucket.s3_upload.arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_artifacts_bucket}"]
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${var.s3_artifacts_bucket}/*"]
  }
}
