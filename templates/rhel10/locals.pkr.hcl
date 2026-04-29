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
  ami_name = "${var.ami_name_prefix}-${local.version}"

  # Build username - defaults to ec2-user for RHEL
  build_username = var.build_username != "" ? var.build_username : "ec2-user"

  # Source AMI metadata used for OS tag derivation
  # Fail fast when source_ami_id is set without a derivable source AMI name.
  source_ami_name = var.source_ami_id == "" ? data.amazon-ami.rhel10.name : ""

  # OS metadata — RHEL 10
  os_major   = split(".", var.rhel_version)[0]
  os_minor   = split(".", var.rhel_version)[1]
  os_release = regexall("[0-9]+\\.[0-9]+\\.[0-9]+_HVM-[0-9]{8}", local.source_ami_name)[0]

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
    OSRelease      = local.os_release
    Architecture   = var.architecture
    Channel        = var.channel
    ReleaseVersion = local.version
    IsRelease      = local.is_release ? "true" : "false"
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
