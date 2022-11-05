# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias
data "aws_kms_alias" "secrets_manager" {
  name = "alias/aws/secretsmanager"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret
resource "aws_secretsmanager_secret" "dockerhub" {
  name = "${var.prefix}/dockerhub"
  kms_key_id = data.aws_kms_alias.secrets_manager.target_key_id

  recovery_window_in_days = 0
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version
resource "aws_secretsmanager_secret_version" "dockerhub" {
  secret_id = aws_secretsmanager_secret.dockerhub.id
  secret_string = jsonencode({
    username = var.dockerhub_username
    password = var.dockerhub_password
  })
  # secret_string = "{\"username\":\"${var.dockerhub_username}\",\"password\":\"${var.dockerhub_password}\"}"
}