terraform {
  # Live modules pin exact Terraform version; generic modules let consumers pin the version.
  # The latest version of Terragrunt (v0.19.0 and above) requires Terraform 0.12.0 or above.
  required_version = "~> 0.12"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    aws = {
      version = "~> 2.70"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "main" {
  name = "dbp"
}

resource "aws_ecs_task_definition" "main" {
  family                   = "dbp-etl"
  task_role_arn            = aws_iam_role.iam_task.arn
  execution_role_arn       = aws_iam_role.iam_execution.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([{
    name  = "dbp-etl"
    image = "${aws_ecr_repository.main.repository_url}:latest"
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "dbp-etl"
      }
    }
    environment = [
      {
        name  = "UPLOAD_BUCKET"
        value = aws_s3_bucket.s3_upload.id
      },
      {
        name  = "DATABASE_USER"
        value = var.database_user
      },
      {
        name  = "DATABASE_PASSWD"
        value = var.database_passwd
      },
      {
        name  = "DATABASE_USER_DB_NAME"
        value = var.database_user_db_name
      },
      {
        name  = "DATABASE_HOST"
        value = var.database_host
      },
      {
        name  = "DATABASE_PORT"
        value = var.database_port
      },
      {
        name  = "DATABASE_DB_NAME"
        value = var.database_db_name
      },
      {
        name  = "S3_BUCKET"
        value = var.s3_bucket
      },
      {
        name  = "S3_VID_BUCKET"
        value = var.s3_vid_bucket
      },
      {
        name  = "S3_ARTIFACTS_BUCKET"
        value = var.s3_artifacts_bucket
      },
    ]
  }])
}

resource "aws_ecr_repository" "main" {
  name = "dbp-etl"
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/dbp-etl"
  retention_in_days = 7
}
