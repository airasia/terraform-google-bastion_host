output "ip_address" {
  description = "The External IP assigned to the bastion host."
  value       = module.vm_instance.static_ip
}
