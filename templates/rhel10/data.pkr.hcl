# ./templates/rhel10/data.pkr.hcl

// Data sources for AWS AMI build
// Secrets pulled from AWS Secrets Manager - similar pattern to the vsphere project
// Must be authenticated and assume a role that has permissions to the secret from the shell that is running packer build

# Optional: Pull build credentials from Secrets Manager
# Uncomment and configure if you need to pull secrets during build

# data "amazon-secretsmanager" "build_secrets" {
#   name   = var.secrets_manager_secret_name
#   key    = "build_vars"
#   region = var.secrets_manager_region
#
#   # assume_role {
#   #   role_arn     = var.aws_assume_role_arn
#   #   session_name = var.aws_assume_role_session_name
#   # }
# }

# Example: Pull specific keys if needed
# data "amazon-secretsmanager" "ssh_private_key" {
#   name   = var.secrets_manager_secret_name
#   key    = "ssh_private_key"
#   region = var.secrets_manager_region
# }
