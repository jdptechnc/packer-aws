# ./templates/rhel10/sources.pkr.hcl

// Source AMI lookup - finds the latest official RHEL 10 AMI
data "amazon-ami" "rhel10" {
  filters = {
    name                = "RHEL-${var.rhel_version}*_HVM*-x86_64-*-Hourly2-GP3"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
    architecture        = "x86_64"
  }
  # Red Hat publishes updated 10.0 AMIs even after 10.1+ is released.
  # The rhel_version variable targets a specific minor version (e.g., "10.1")
  # to avoid selecting newer 10.0 builds over the desired release.
  # Update rhel_version in pkrvars when a new minor becomes available.
  owners      = [var.source_ami_filter_owner]
  most_recent = true
  region      = var.aws_region
}

// Amazon EBS source configuration for RHEL 10
source "amazon-ebs" "rhel10" {
  # AMI Configuration
  ami_name        = local.ami_name
  ami_description = var.ami_description
  ami_regions     = var.ami_regions
  ami_users       = var.ami_users
  ami_org_arns    = var.ami_org_arns

  # Encryption
  encrypt_boot = var.encrypt_boot
  kms_key_id   = var.kms_key_id != "" ? var.kms_key_id : null

  # Source AMI - use specific ID if provided, otherwise use data source lookup
  source_ami = var.source_ami_id != "" ? var.source_ami_id : data.amazon-ami.rhel10.id

  # Instance Configuration
  instance_type        = var.instance_type
  region               = var.aws_region
  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  # Temporary IAM instance profile for SSM connectivity when no iam_instance_profile is set.
  # Packer creates this role, attaches it for the build, and deletes it on completion.
  # This block is ignored when iam_instance_profile is set (the two are mutually exclusive
  # only if iam_instance_profile is non-null; a null value defers to this block).
  # Equivalent to AWS managed policy: AmazonSSMManagedInstanceCore
  temporary_iam_instance_profile_policy_document {
    Statement {
      Action = [
        "ssm:DescribeAssociation",
        "ssm:GetDeployablePatchSnapshotForInstance",
        "ssm:GetDocument",
        "ssm:DescribeDocument",
        "ssm:GetManifest",
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:ListAssociations",
        "ssm:ListInstanceAssociations",
        "ssm:PutInventory",
        "ssm:PutComplianceItems",
        "ssm:PutConfigurePackageResult",
        "ssm:UpdateAssociationStatus",
        "ssm:UpdateInstanceAssociationStatus",
        "ssm:UpdateInstanceInformation",
      ]
      Effect   = "Allow"
      Resource = ["*"]
    }
    Statement {
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
      ]
      Effect   = "Allow"
      Resource = ["*"]
    }
    Statement {
      Action = [
        "ec2messages:AcknowledgeMessage",
        "ec2messages:DeleteMessage",
        "ec2messages:FailMessage",
        "ec2messages:GetEndpoint",
        "ec2messages:GetMessages",
        "ec2messages:SendReply",
      ]
      Effect   = "Allow"
      Resource = ["*"]
    }
  }

  # VPC/Network Configuration
  vpc_id                      = var.vpc_id != "" ? var.vpc_id : null
  subnet_id                   = var.subnet_id != "" ? var.subnet_id : null
  security_group_id           = var.security_group_id != "" ? var.security_group_id : null
  associate_public_ip_address = var.associate_public_ip
  ssh_interface               = var.ssh_interface

  # Temporary security group (created if security_group_id not specified)
  temporary_security_group_source_cidrs = var.security_group_id == "" ? ["0.0.0.0/0"] : null

  # EBS Volume Configuration
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    iops                  = var.root_volume_type == "gp3" || var.root_volume_type == "io1" || var.root_volume_type == "io2" ? var.root_volume_iops : null
    throughput            = var.root_volume_type == "gp3" ? var.root_volume_throughput : null
    delete_on_termination = var.delete_on_termination
    encrypted             = var.encrypt_boot
  }

  # SSH/Communicator Settings
  communicator         = "ssh"
  ssh_username         = local.build_username
  ssh_timeout          = var.communicator_timeout
  ssh_pty              = true
  
  # SSM: pause to allow SSM agent to register before Packer opens the session
  pause_before_ssm = var.pause_before_ssm

  # EC2 Key Pair - use existing key pair or let Packer create a temporary one
  ssh_keypair_name     = var.ssh_keypair_name != "" ? var.ssh_keypair_name : null
  ssh_private_key_file = var.ssh_private_key_file != "" ? var.ssh_private_key_file : null
  # If neither is set, Packer creates a temporary key pair automatically

  # IMDSv2 Configuration (security best practice)
  imds_support = var.imds_support
  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
  }

  # Tags
  tags     = local.common_tags
  run_tags = local.run_tags

  # Snapshot tags (inherits from tags)
  snapshot_tags = local.common_tags

  # AWS Authentication (optional - will use env vars or instance profile if not set)
  access_key = var.aws_access_key != "" ? var.aws_access_key : null
  secret_key = var.aws_secret_key != "" ? var.aws_secret_key : null

  # Assume role if specified
  dynamic "assume_role" {
    for_each = var.aws_assume_role_arn != "" ? [1] : []
    content {
      role_arn     = var.aws_assume_role_arn
      session_name = var.aws_assume_role_session_name
    }
  }
}
