terraform {
  required_version = ">= 0.13.1" # see https://releases.hashicorp.com/terraform/
}

module "vm_instance" {
  source                 = "airasia/vm_instance/google"
  version                = "2.10.0"
  name_suffix            = var.name_suffix
  instance_name          = var.instance_name
  network_tags           = ["bastion"]
  boot_disk_image_source = var.disk_image
  boot_disk_size         = var.disk_size
  vpc_subnetwork         = var.vpc_subnet
  sa_roles               = var.sa_roles
  sa_description         = "Manages permissions available to the VPC Bastion Host"
  allow_login            = true
  login_user_groups      = var.login_user_groups
  login_service_accounts = var.login_service_accounts
}
