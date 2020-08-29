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
  pre_defined_sa_roles = [
    # enable the bastion host to write logs and metrics
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer"
  ]
}

resource "google_project_service" "networking_api" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

module "service_account" {
  source       = "airasia/service_account/google"
  version      = "1.2.1"
  providers    = { google = google }
  name_suffix  = var.name_suffix
  name         = var.sa_name
  display_name = var.sa_name
  description  = "Manages permissions available to the VPC Bastion Host"
  roles        = toset(concat(local.pre_defined_sa_roles, var.sa_roles))
}

module "vm_instance" {
  source                 = "airasia/vm_instance/google"
  version                = "1.1.3"
  providers              = { google = google }
  name_suffix            = var.name_suffix
  name                   = var.instance_name
  tags                   = local.vm_tags
  boot_disk_image_source = var.disk_image
  vpc_subnetwork         = var.vpc_subnet
  service_account_email  = module.service_account.email
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

resource "google_project_iam_member" "login_role_iap_secured_tunnel_user" {
  count      = length(var.user_groups)
  role       = "roles/iap.tunnelResourceAccessor"
  member     = "group:${var.user_groups[count.index]}"
  depends_on = [google_compute_firewall.outside_to_bastion_firewall]
}

resource "google_project_iam_member" "login_role_service_account_user" {
  count      = length(var.user_groups)
  role       = "roles/iam.serviceAccountUser"
  member     = "group:${var.user_groups[count.index]}"
  depends_on = [google_compute_firewall.outside_to_bastion_firewall]
  # see https://cloud.google.com/compute/docs/instances/managing-instance-access#configure_users
}

resource "google_project_iam_member" "login_role_compute_OS_login" {
  count      = length(var.user_groups)
  role       = "roles/compute.osLogin"
  member     = "group:${var.user_groups[count.index]}"
  depends_on = [google_compute_firewall.outside_to_bastion_firewall]
  # see https://cloud.google.com/compute/docs/instances/managing-instance-access#configure_users
}

data "google_client_config" "google_client" {}
