# ./templates/rhel10/locals.pkr.hcl

// Local variables for AWS AMI build

locals {
  # Build metadata
  build_by          = "Built by: HashiCorp Packer ${packer.version}"
  build_date        = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  build_timestamp   = formatdate("YYYYMMDD-hhmmss", timestamp())
  build_description = "RHEL 10 Golden AMI | Built on: ${local.build_date} | ${local.build_by}"

  # AMI naming - includes timestamp for uniqueness
  ami_name = "${var.ami_name_prefix}-${local.build_timestamp}"

  # Build username - defaults to ec2-user for RHEL
  build_username = var.build_username != "" ? var.build_username : "ec2-user"

  # Merged tags with build metadata
  common_tags = merge(var.tags, {
    BuildDate   = local.build_date
    BuildBy     = local.build_by
    SourceAMI   = "{{ .SourceAMI }}"
    SourceAMIName = "{{ .SourceAMIName }}"
  })

  # Run tags for build instance
  # GitHubRunId enables the workflow cleanup job to find and terminate this
  # instance by tag if the build is cancelled or errors before Packer cleans up.
  run_tags = merge(var.run_tags, {
    BuildTimestamp = local.build_timestamp
    GitHubRunId    = var.github_run_id
  })

  # Manifest output path
  manifest_path   = "${path.cwd}/manifests/"
  manifest_output = "${local.manifest_path}${local.build_timestamp}-rhel10-ami.json"
}
