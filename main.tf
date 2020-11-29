locals {
  deprecation_message = "Module **airasia/bastion_host/google** has been deprecated in favor of module **airasia/vm_instance/google** version **2.11.0**. See deprecation guide in README of **airasia/bastion_host/google** module."
}

resource "null_resource" "deprecation_message" {
  provisioner "local-exec" {
    command = "echo ${local.deprecation_message}"
  }
}
