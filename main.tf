terraform {
  required_version = ">= 0.12.24" # see https://releases.hashicorp.com/terraform/
  experiments      = [variable_validation]
}

provider "google" {
  version = ">= 3.13.0" # see https://github.com/terraform-providers/terraform-provider-google/releases
}

locals {
  # for VM Instance --------------------------------------------------------------------------------
  vm_name          = "bastion-host"
  network_zone     = format("%s-a", data.google_client_config.google_client.region)
  vm_tags          = ["bastion"]
  external_ip_name = format("bastion-external-ip-%s", var.name_suffix)

  # for Firewalls ----------------------------------------------------------------------------------
  vm_firewall_name      = format("outside-to-bastion-%s", var.name_suffix)
  network_firewall_name = format("bastion-to-network-%s", var.name_suffix)
  google_iap_cidr       = "35.235.240.0/20" # GCloud Identity Aware Proxy Netblock - https://cloud.google.com/iap/docs/using-tcp-forwarding#before_you_begin
  all_allowed_IPs       = toset(concat(var.allowed_IPs, [local.google_iap_cidr /* see https://stackoverflow.com/a/57024714/636762 */]))
}

resource "google_project_service" "networking_api" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_address" "external_ip" {
  name       = local.external_ip_name
  region     = data.google_client_config.google_client.region
  depends_on = [google_project_service.networking_api]
  timeouts {
    create = var.ip_address_timeout
    delete = var.ip_address_timeout
  }
}

module "service_account" {
  source       = "airasia/service_account/google"
  version      = "1.2.0"
  providers    = { google = google }
  name_suffix  = var.name_suffix
  account_id   = "bastion-host-sa"
  display_name = "BastionHost-ServiceAccount"
  description  = "Manages permissions available to the VPC Bastion Host"
  roles        = var.sa_roles
}

module "vm_instance" {
  source                 = "airasia/vm_instance/google"
  version                = "1.1.1"
  providers              = { google = google }
  name_suffix            = var.name_suffix
  name                   = local.vm_name
  zone                   = local.network_zone
  tags                   = local.vm_tags
  boot_disk_image_source = var.disk_image
  vpc_subnetwork         = var.vpc_subnet
  static_ip              = google_compute_address.external_ip.address
  service_account_email  = module.service_account.email
}

resource "google_compute_firewall" "gshell_to_bastion_firewall" {
  name          = local.vm_firewall_name
  network       = var.vpc_network
  source_ranges = local.all_allowed_IPs
  target_tags   = local.vm_tags
  depends_on    = [module.vm_instance.ip_address, google_project_service.networking_api]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "bastion_to_network_firewall" {
  name        = local.network_firewall_name
  network     = var.vpc_network
  source_tags = local.vm_tags
  depends_on  = [module.vm_instance.ip_address, google_project_service.networking_api]
  allow { protocol = "icmp" }
  allow { protocol = "tcp" }
  allow { protocol = "udp" }
}

resource "google_project_iam_member" "login_role_iap_secured_tunnel_user" {
  count      = length(var.user_groups)
  role       = "roles/iap.tunnelResourceAccessor"
  member     = "group:${var.user_groups[count.index]}"
  depends_on = [google_compute_firewall.gshell_to_bastion_firewall]
}

resource "google_project_iam_member" "login_role_service_account_user" {
  count      = length(var.user_groups)
  role       = "roles/iam.serviceAccountUser"
  member     = "group:${var.user_groups[count.index]}"
  depends_on = [google_compute_firewall.gshell_to_bastion_firewall]
  # see https://cloud.google.com/compute/docs/instances/managing-instance-access#configure_users
}

resource "google_project_iam_member" "login_role_compute_OS_login" {
  count      = length(var.user_groups)
  role       = "roles/compute.osLogin"
  member     = "group:${var.user_groups[count.index]}"
  depends_on = [google_compute_firewall.gshell_to_bastion_firewall]
  # see https://cloud.google.com/compute/docs/instances/managing-instance-access#configure_users
}

data "google_client_config" "google_client" {}
