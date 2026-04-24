# ./templates/rhel10/plugins.pkr.hcl
# Required Plugins for AWS AMI builds

packer {
  required_version = ">= 1.8.5"
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }

    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}
