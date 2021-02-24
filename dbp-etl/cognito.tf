resource "aws_cognito_user_pool" "cognito" {
  name                = random_string.random.result
  username_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

resource "aws_cognito_user_pool_client" "cognito" {
  name                                 = random_string.random.result
  user_pool_id                         = aws_cognito_user_pool.cognito.id
  prevent_user_existence_errors        = "ENABLED"
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls = [
    "http://localhost:8080",
    "https://${aws_cloudfront_distribution.cloudfront.domain_name}",
  ]
  logout_urls = [
    "http://localhost:8080",
    "https://${aws_cloudfront_distribution.cloudfront.domain_name}",
  ]
}

resource "aws_cognito_user_pool_domain" "cognito" {
  domain       = random_string.random.result
  user_pool_id = aws_cognito_user_pool.cognito.id
}

resource "aws_cognito_identity_pool" "cognito" {
  identity_pool_name               = random_string.random.result
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.cognito.id
    provider_name           = aws_cognito_user_pool.cognito.endpoint
    server_side_token_check = true
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "cognito" {
  identity_pool_id = aws_cognito_identity_pool.cognito.id
  roles = {
    authenticated = aws_iam_role.iam_authenticated.arn
  }
}
