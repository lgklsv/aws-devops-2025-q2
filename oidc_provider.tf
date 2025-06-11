resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "GitHub Actions OIDC Provider"
  }
}

output "github_oidc_provider_arn" {
  description = "The ARN of the GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github_actions.arn
}