# ./templates/rhel10/build.pkr.hcl

build {
  name    = "rhel10-golden-ami"
  sources = ["source.amazon-ebs.rhel10"]

  # Provisioner: Wait for cloud-init to complete before running other provisioners
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "sudo cloud-init status --wait",
      "echo 'Cloud-init complete.'"
    ]
  }

  # Provisioner: Base configurations (hardening, patching, etc.)
  # Reuses the same Ansible pattern from the vsphere project
  provisioner "ansible" {
    user          = local.build_username
    playbook_file = "${abspath(path.root)}/ansible/configure.yml"
    roles_path    = "${abspath(path.root)}/ansible/roles"
    use_proxy     = false  # Connect directly to instance, bypass Packer's SSH proxy
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${abspath(path.root)}/ansible/ansible.cfg",
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_FORCE_COLOR=1"
    ]
    extra_arguments = [
    #   "-v",  # Verbose output for debugging
      "--extra-vars", "display_skipped_hosts=false",
      "--extra-vars", "target_platform=aws",
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
    ]
    max_retries = 1
  }

  # Provisioner: CIS Benchmark / Techspec compliance
  provisioner "ansible" {
    pause_before  = "5s"
    user          = local.build_username
    playbook_file = "${abspath(path.root)}/ansible/security.yml"
    roles_path    = "${abspath(path.root)}/ansible/roles"
    use_proxy     = false
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${abspath(path.root)}/ansible/ansible.cfg",
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_FORCE_COLOR=1"
    ]
    extra_arguments = [
      "--extra-vars", "display_skipped_hosts=false",
      "--extra-vars", "target_platform=aws",
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
    ]
    max_retries = 1
  }

  # Provisioner: Techspec hardening (disabled until techspec automation repo is integrated)
  # To re-enable: restore from build-full.pkr.hcl.disabled or uncomment below
  #
  # provisioner "ansible" {
  #   pause_before  = "5s"
  #   user          = local.build_username
  #   playbook_file = "${abspath(path.root)}/ansible/techspec/main.yml"
  #   roles_path    = "${abspath(path.root)}/ansible/roles"
  #   use_proxy     = false
  #   ansible_env_vars = [
  #     "ANSIBLE_CONFIG=${abspath(path.root)}/ansible/ansible.cfg",
  #     "ANSIBLE_HOST_KEY_CHECKING=False",
  #     "ANSIBLE_FORCE_COLOR=1"
  #   ]
  #   extra_arguments = [
  #     "--extra-vars", "display_skipped_hosts=false",
  #     "--extra-vars", "target_platform=aws",
  #     "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
  #   ]
  #   max_retries = 1
  # }

  # Provisioner: Cleanup before creating AMI
  provisioner "ansible" {
    pause_before  = "5s"
    user          = local.build_username
    playbook_file = "${abspath(path.root)}/ansible/clean.yml"
    roles_path    = "${abspath(path.root)}/ansible/roles"
    use_proxy     = false  # Connect directly to instance, bypass Packer's SSH proxy
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${abspath(path.root)}/ansible/ansible.cfg",
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_FORCE_COLOR=1"
    ]
    extra_arguments = [
    #   "-v",  # Verbose output for debugging
      "--extra-vars", "display_skipped_hosts=false",
      "--extra-vars", "target_platform=aws",
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
    ]
    max_retries = 1
  }

  # Post-processor: Generate manifest file
  post-processor "manifest" {
    output     = local.manifest_output
    strip_path = true
    custom_data = {
      build_date  = local.build_date
      ami_name    = local.ami_name
      source_ami  = "{{ .SourceAMI }}"
      aws_region  = var.aws_region
    }
  }
}
