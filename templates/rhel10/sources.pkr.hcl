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

  # Terminate instance on shutdown rather than stop — ensures Packer-launched
  # instances are never left in a stopped state consuming EBS costs.
  shutdown_behavior = "terminate"

  # RHEL 10 does not ship with SSM agent pre-installed. Install and start it at
  # boot so the instance registers with SSM before Packer opens the session.
  #
  # IAM PERMISSIONS required on packer-ssm role (beyond AmazonSSMManagedInstanceCore):
  #   s3:PutObject   on arn:aws:s3:::jdp-packer-debug-logs/*  — log upload
  #   ec2:CreateTags on *                                      — status tag
  #
  # VPC ENDPOINTS required (private subnet, no IGW):
  #   S3 Gateway           — SSM agent RPM download + log upload
  #   ssm Interface        — SSM API
  #   ssmmessages Interface— session data channel
  #   ec2messages Interface— SSM agent heartbeat
  #   ec2 Interface        — ec2:CreateTags for status signal
  # Interface endpoints: private DNS enabled, SG allows inbound TCP 443 from subnet CIDR.
  user_data = <<-USER_DATA
  #!/bin/bash
  exec >> /var/log/user-data.log 2>&1
  set -x

  # Instance metadata via IMDSv2
  IMDS_TOKEN=$(curl -fsSL -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
  INSTANCE_ID=$(curl -fsSL -H "X-aws-ec2-metadata-token: $${IMDS_TOKEN}" \
    http://169.254.169.254/latest/meta-data/instance-id)
  REGION=$(curl -fsSL -H "X-aws-ec2-metadata-token: $${IMDS_TOKEN}" \
    http://169.254.169.254/latest/meta-data/placement/region)
  echo "Instance: $${INSTANCE_ID}  Region: $${REGION}"

  # Exit handler — runs on any exit (success or failure).
  # Uploads /var/log/user-data.log to S3 and tags the instance with final status.
  USER_DATA_STATUS="failed"
  cleanup() {
    set +e
    if command -v aws &>/dev/null; then
      aws s3 cp /var/log/user-data.log \
        "s3://jdp-packer-debug-logs/$${INSTANCE_ID}/user-data.log" \
        --region "$${REGION}"
      aws ec2 create-tags \
        --region "$${REGION}" \
        --resources "$${INSTANCE_ID}" \
        --tags "Key=UserDataStatus,Value=$${USER_DATA_STATUS}"
    else
      echo "WARN: aws CLI not available — skipping S3 upload and EC2 tag"
    fi
  }
  trap cleanup EXIT

  # Install AWS CLI so cleanup() can signal status.
  if ! command -v aws &>/dev/null; then
    echo "=== Installing AWS CLI ==="
    dnf install -y awscli || echo "WARN: awscli not available from repos"
  fi

  # Install SSM agent — not pre-installed on RHEL 10.
  echo "=== Installing amazon-ssm-agent ==="
  dnf install -y \
    "https://s3.$${REGION}.amazonaws.com/amazon-ssm-agent/latest/linux_amd64/amazon-ssm-agent.rpm" \
    || dnf install -y amazon-ssm-agent \
    || { echo "ERROR: SSM agent install failed"; exit 1; }

  systemctl enable --now amazon-ssm-agent
  systemctl is-active --quiet amazon-ssm-agent \
    || { echo "ERROR: SSM agent failed to start"; exit 1; }
  echo "SSM agent is active"

  USER_DATA_STATUS="success"
  echo "=== user-data complete ==="
  USER_DATA

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
