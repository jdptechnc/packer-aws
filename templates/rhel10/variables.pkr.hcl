/*
    DESCRIPTION:
    Red Hat Enterprise Linux 10 variables using the Packer Builder for Amazon EBS (amazon-ebs).
*/

//  BLOCK: variable
//  Defines the input variables.

// AWS Region and Credentials

variable "aws_region" {
  type        = string
  description = "The AWS region to build the AMI in. (e.g. 'us-east-1')"
  default     = "us-east-1"
}

variable "aws_access_key" {
  type        = string
  description = "The AWS access key. Leave empty to use environment variables or instance profile."
  sensitive   = true
  default     = ""
}

variable "aws_secret_key" {
  type        = string
  description = "The AWS secret key. Leave empty to use environment variables or instance profile."
  sensitive   = true
  default     = ""
}

variable "aws_assume_role_arn" {
  type        = string
  description = "ARN of the IAM role to assume for the build. (optional)"
  default     = ""
}

variable "aws_assume_role_session_name" {
  type        = string
  description = "Session name when assuming an IAM role."
  default     = "packer-rhel10-build"
}

// AMI Configuration

variable "ami_name_prefix" {
  type        = string
  description = "Prefix for the AMI name. (e.g. 'rhel10-golden')"
  default     = "rhel10-golden"
}

variable "ami_description" {
  type        = string
  description = "Description for the AMI."
  default     = "RHEL 10 Golden AMI built with Packer"
}

variable "ami_regions" {
  type        = list(string)
  description = "List of regions to copy the AMI to."
  default     = []
}

variable "ami_users" {
  type        = list(string)
  description = "List of AWS account IDs to share the AMI with."
  default     = []
}

variable "ami_org_arns" {
  type        = list(string)
  description = "List of AWS Organization ARNs to share the AMI with."
  default     = []
}

variable "encrypt_boot" {
  type        = bool
  description = "Encrypt the root volume of the AMI."
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID or ARN for encrypting the AMI. Leave empty to use default key."
  default     = ""
}

// Source AMI Configuration

variable "rhel_version" {
  type        = string
  description = "RHEL minor version to use (e.g., '10.1', '10.2'). Update this when a new minor release becomes available. Red Hat publishes updated 10.0 AMIs alongside newer releases, so specifying the exact minor version ensures the correct stream."
  default     = "10.1"
}

variable "source_ami_filter_owner" {
  type        = string
  description = "Owner ID for the source AMI. Red Hat's owner ID is 309956199498."
  default     = "309956199498"
}

variable "source_ami_id" {
  type        = string
  description = "Specific source AMI ID to use. If set, this overrides the filter."
  default     = ""
}

// Instance Configuration

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the build. (e.g. 't3.medium')"
  default     = "t3.medium"
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile to attach to the build instance. Required for SSM Session Manager."
  default     = "packer-ssm"
}

variable "github_run_id" {
  type        = string
  description = "GitHub Actions run ID, used as a run tag for identifying and cleaning up build instances. Set automatically via PKR_VAR_github_run_id in CI."
  default     = "local"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the build instance will be launched. Leave empty to use default VPC."
  default     = ""
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the build instance will be launched. Leave empty to use default."
  default     = ""
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach to the build instance. Leave empty to create temporary one."
  default     = ""
}

variable "associate_public_ip" {
  type        = bool
  description = "Associate a public IP address with the build instance."
  default     = true
}

variable "ssh_interface" {
  type        = string
  description = "The interface to use for SSH connections. (public_ip, private_ip, public_dns, private_dns, session_manager)"
  default     = "public_ip"
}

// EBS Volume Configuration

variable "root_volume_size" {
  type        = number
  description = "Size of the root volume in GB."
  default     = 30
}

variable "root_volume_type" {
  type        = string
  description = "Type of EBS volume. (gp2, gp3, io1, io2)"
  default     = "gp3"
}

variable "root_volume_iops" {
  type        = number
  description = "IOPS for the root volume (only for gp3, io1, io2)."
  default     = 3000
}

variable "root_volume_throughput" {
  type        = number
  description = "Throughput in MB/s for gp3 volumes."
  default     = 125
}

variable "delete_on_termination" {
  type        = bool
  description = "Delete the root volume on instance termination."
  default     = true
}

// Build Settings

variable "build_username" {
  type        = string
  description = "The username to login to the instance. (default for RHEL is 'ec2-user')"
  sensitive   = true
  default     = "ec2-user"
}

variable "communicator_timeout" {
  type        = string
  description = "SSH timeout for the communicator."
  default     = "30m"
}

// EC2 Key Pair Settings

variable "ssh_keypair_name" {
  type        = string
  description = "Name of an existing EC2 key pair to use for SSH. If empty, Packer creates a temporary key pair."
  default     = ""
}

variable "ssh_private_key_file" {
  type        = string
  description = "Path to the private key file for the EC2 key pair. Required if ssh_keypair_name is set."
  sensitive   = true
  default     = ""
}

variable "pause_before_ssm" {
  type        = string
  description = "Pause before SSM connection."
  default     = "60s"
}

// Tags

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the AMI and snapshots."
  default = {
    Environment = "golden-image"
    OS          = "RHEL10"
    ManagedBy   = "Packer"
  }
}

variable "run_tags" {
  type        = map(string)
  description = "Tags to apply to the build instance."
  default = {
    Name = "packer-rhel10-build"
  }
}

// Secrets Manager Configuration (reusing from vsphere project pattern)

variable "secrets_manager_region" {
  type        = string
  description = "AWS region for Secrets Manager lookups."
  default     = "us-east-1"
}

variable "secrets_manager_secret_name" {
  type        = string
  description = "Name or ARN of the secret in AWS Secrets Manager."
  default     = ""
}

// HCP Packer Settings

variable "hcp_packer_registry_enabled" {
  type        = bool
  description = "Enable the HCP Packer registry."
  default     = false
}

// IMDSv2 Settings

variable "imds_support" {
  type        = string
  description = "IMDSv2 support. Values: v2.0 (required) or empty for optional."
  default     = "v2.0"
}

variable "metadata_options" {
  type = object({
    http_endpoint               = string
    http_tokens                 = string
    http_put_response_hop_limit = number
  })
  description = "Metadata options for IMDSv2."
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
}
