# RHEL 10 Golden AMI - Packer Build

This project builds a hardened RHEL 10 Golden AMI for AWS using HashiCorp Packer.

## Prerequisites

- Packer >= 1.8.5
- Ansible
- AWS CLI configured with appropriate credentials
- Network access to the target VPC/subnet

## Quick Start

1. **Initialize Packer plugins:**
   ```bash
   packer init .
   ```

2. **Customize variables:**
   Edit `rhel10.auto.pkrvars.hcl` to match your environment:
   - AWS region
   - VPC/Subnet IDs
   - IAM instance profile
   - Source AMI filter

3. **Validate the configuration:**
   ```bash
   packer validate .
   ```

4. **Build the AMI:**
   ```bash
   packer build .
   ```

## Project Structure

```
rhel10/
├── build.pkr.hcl           # Build configuration with provisioners
├── sources.pkr.hcl         # Source AMI and builder configuration
├── variables.pkr.hcl       # Input variable definitions
├── locals.pkr.hcl          # Local variables and computed values
├── plugins.pkr.hcl         # Required Packer plugins
├── data.pkr.hcl            # Data sources (Secrets Manager, etc.)
├── rhel10.auto.pkrvars.hcl # Variable values (customize this)
├── ansible/
│   ├── ansible.cfg         # Ansible configuration
│   ├── configure.yml       # System configuration playbook
│   ├── clean.yml           # Pre-AMI cleanup playbook
│   └── roles/              # Custom Ansible roles
└── manifests/              # Build output manifests
```

## Ansible Playbooks

### configure.yml
- System updates and patching
- Required package installation
- AWS CLI v2 installation
- Chrony NTP configuration (Amazon Time Sync)
- SSH hardening
- Cloud-init configuration
- Audit daemon setup

### clean.yml
- Stop logging services
- Clean package cache
- Truncate log files
- Remove temporary files
- Clean machine-id (important for cloning)
- Clean cloud-init state
- Remove SSH host keys (regenerated on first boot)

## Key Differences from RHEL 9

- Updated AMI filter for RHEL 10: `RHEL-10*_HVM*-x86_64-*`
- No `Protocol 2` in SSH config (deprecated in OpenSSH 8.0+)
- Compatible with RHEL 10 package names and paths

## Customization

### Adding Custom Roles
Place custom Ansible roles in `ansible/roles/` and include them in the playbooks.

### Sharing AMI
Configure `ami_users` or `ami_org_arns` in the variables file to share the AMI with other AWS accounts.

### Cross-Region Copy
Set `ami_regions` to copy the AMI to additional AWS regions after build.
