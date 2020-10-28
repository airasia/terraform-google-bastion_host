output "login_IAM_roles" {
  description = "IAM role(s) that are necessary for logging in to the bastion host. See https://cloud.google.com/compute/docs/instances/managing-instance-access#configure_users."
  value       = module.vm_instance.login_IAM_roles
}

output "sa_roles" {
  description = "All roles (except sensitive roles filtered by the module) that are attached to the ServiceAccount generated for this Bastion Host."
  value       = module.vm_instance.sa_roles
}
