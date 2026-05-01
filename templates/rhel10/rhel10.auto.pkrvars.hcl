# Example variables file for RHEL 10 Golden AMI build
# Copy this file to rhel10.auto.pkrvars.hcl and customize as needed

# AWS Region
aws_region = "us-east-1"

# AMI Configuration
ami_name_prefix = "rhel10-golden"
ami_description = "RHEL 10 Golden AMI - Hardened and configured by Packer"

# Optional: Copy AMI to additional regions
# ami_regions = ["us-west-2", "eu-west-1"]

# Optional: Share AMI with other AWS accounts
# ami_users = ["123456789012", "987654321098"]

# Encryption
encrypt_boot = true
# kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# Source AMI Configuration
# Uses the latest official RHEL 10 AMI from Red Hat.
# Update this when a new minor release becomes available (10.2, etc.).
rhel_version            = "10.1"
source_ami_filter_owner = "309956199498"  # Red Hat's AWS account

# Or specify a specific AMI ID:
# source_ami_id = "ami-0123456789abcdef0"

# Instance Configuration
instance_type = "t3.medium"

# IAM Instance Profile (optional — only needed for SSM Session Manager)
# iam_instance_profile = "packer-ssm"

# Network Configuration
# VPC and subnet are passed via workflow -var flags; do not set here.
# vpc_id    = "vpc-0c53ca94f5f3ccf98"
# subnet_id = "subnet-021f82e53d9618d11"

# Set to false if building in a private subnet with NAT
# associate_public_ip = true
# ssh_interface       = "public_ip"

# For private subnet builds with self-hosted runner in same VPC:
associate_public_ip = false
ssh_interface       = "private_ip"

# EBS Volume Configuration
root_volume_size       = 30
root_volume_type       = "gp3"
root_volume_iops       = 3000
root_volume_throughput = 125

# Build Settings
build_username       = "ec2-user"
communicator_timeout = "30m"

# Tags
tags = {
  Environment = "golden-image"
  ManagedBy   = "Packer"
  # Project     = "infrastructure"
  # CostCenter  = "it-infrastructure"
}

run_tags = {
  Name    = "packer-rhel10-build"
  Purpose = "ami-build"
}

# IMDSv2 Configuration (required for security compliance)
imds_support = "v2.0"
metadata_options = {
  http_endpoint               = "enabled"
  http_tokens                 = "required"
  http_put_response_hop_limit = 2
}

# Optional: Assume role for build
# aws_assume_role_arn          = "arn:aws:iam::123456789012:role/PackerBuildRole"
# aws_assume_role_session_name = "packer-rhel10-build"

# HCP Packer Registry (optional)
hcp_packer_registry_enabled = false
