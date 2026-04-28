# ./templates/rhel10/locals.pkr.hcl

// Local variables for AWS AMI build

locals {
  # Build metadata
  build_by          = "Built by: HashiCorp Packer ${packer.version}"
  build_date        = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  build_timestamp   = formatdate("YYYYMMDD-hhmmss", timestamp())
  build_description = "RHEL 10 Golden AMI | Built on: ${local.build_date} | ${local.build_by}"

  # Versioning — release builds use CalVer, test builds use timestamp
  is_release = var.version != ""
  version    = local.is_release ? var.version : "test-${local.build_timestamp}"

  # AMI naming — release: rhel10-golden-2026.2.0, test: rhel10-golden-test-YYYYMMDD-HHMMSS
  ami_name = local.is_release ? "${var.ami_name_prefix}-${var.version}" : "${var.ami_name_prefix}-test-${local.build_timestamp}"

  # Build username - defaults to ec2-user for RHEL
  build_username = var.build_username != "" ? var.build_username : "ec2-user"

  # OS metadata — RHEL 10
  # OSRelease reflects the configured minor stream (major.minor, e.g., "10.1").
  # The full release including patch level is available in the SourceAmiName tag at runtime.
  os_major   = split(".", var.rhel_version)[0]
  os_minor   = split(".", var.rhel_version)[1]
  os_release = var.rhel_version

  # Merged tags applied to the AMI and snapshots
  common_tags = merge(var.tags, {
    Name           = local.ami_name
    BuildDate      = local.build_date
    BuildTimestamp = local.build_timestamp
    BuildBy        = local.build_by
    SourceAmiId    = "{{ .SourceAMI }}"
    SourceAmiName  = "{{ .SourceAMIName }}"
    OSFamily       = "Linux"
    OSDistro       = "RHEL"
    OSMajor        = local.os_major
    OSMinor        = local.os_minor
    OSVersion      = var.rhel_version
    OSRelease      = local.os_release
    Architecture   = var.architecture
    Channel        = var.channel
    Version        = local.version
    Release        = local.is_release ? "true" : "false"
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
