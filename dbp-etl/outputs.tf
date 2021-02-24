output "aws_region" {
  value = data.aws_region.current.name
}

output "ecs_subnets" {
  value = jsonencode(var.ecs_subnets)
}

output "ecs_security_group" {
  value = var.ecs_security_group
}

output "cognito_domain" {
  value = "${aws_cognito_user_pool_domain.cognito.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

output "cognito_identity_pool_id" {
  value = aws_cognito_identity_pool.cognito.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.cognito.id
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.cognito.id
}

output "upload_bucket" {
  value = aws_s3_bucket.s3_upload.id
}

output "artifacts_bucket" {
  value = var.s3_artifacts_bucket
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cloudfront.domain_name
}
