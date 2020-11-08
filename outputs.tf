output "sa_roles" {
  description = "All roles (except sensitive roles filtered by the module) that are attached to the ServiceAccount generated for this Bastion Host."
  value       = module.vm_instance.sa_roles
}
