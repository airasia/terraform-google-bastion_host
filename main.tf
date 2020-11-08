terraform {
  required_version = ">= 0.13.1" # see https://releases.hashicorp.com/terraform/
}

locals {
  # for VM Instance --------------------------------------------------------------------------------
  vm_tags = ["bastion"]

  # for Firewalls ----------------------------------------------------------------------------------
  vm_firewall_name      = format("outside-to-bastion-%s", var.name_suffix)
  network_firewall_name = format("bastion-to-network-%s", var.name_suffix)
  google_iap_cidr       = "35.235.240.0/20" # GCloud Identity Aware Proxy Netblock - https://cloud.google.com/iap/docs/using-tcp-forwarding#preparing_your_project_for_tcp_forwarding
}

resource "google_project_service" "networking_api" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

module "vm_instance" {
  source                 = "airasia/vm_instance/google"
  version                = "2.8.0"
  name_suffix            = var.name_suffix
  instance_name          = var.instance_name
  tags                   = local.vm_tags
  boot_disk_image_source = var.disk_image
  boot_disk_size         = var.disk_size
  vpc_subnetwork         = var.vpc_subnet
  sa_roles               = var.sa_roles
  sa_description         = "Manages permissions available to the VPC Bastion Host"
  login_user_groups      = var.login_user_groups
}

resource "google_compute_firewall" "outside_to_bastion_firewall" {
  name          = local.vm_firewall_name
  network       = var.vpc_network
  source_ranges = [local.google_iap_cidr /* see https://stackoverflow.com/a/57024714/636762 */]
  target_tags   = local.vm_tags
  depends_on    = [module.vm_instance.static_ip, google_project_service.networking_api]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "bastion_to_network_firewall" {
  name        = local.network_firewall_name
  network     = var.vpc_network
  source_tags = local.vm_tags
  depends_on  = [module.vm_instance.static_ip, google_project_service.networking_api]
  allow { protocol = "icmp" }
  allow { protocol = "tcp" }
  allow { protocol = "udp" }
}

data "google_client_config" "google_client" {}
