output "static_ip" {
  description = "The Static IP address attached to the bastion host."
  value       = module.vm_instance.static_ip
}
