Terraform module for a Bastion Host in GCP

# DEPRECATED

This module has been deprecated in favor of [**vm_instance v2.11.0**](https://registry.terraform.io/modules/airasia/vm_instance/google/2.11.0). See deprecation guide below.

## Deprecation guide

First make sure you've planned & applied this **bastion_host** module with `v2.8.0`.

Then do the following changes:

* change module source from `airasia/bastion_host/google` to `airasia/vm_instance/google`
* change module version from `2.8.0` to `2.11.0`
* change the following argument names:
  * `vpc_subnet` -> `vpc_subnetwork`
  * `disk_image` -> `boot_disk_image`
  * `disk_size` -> `boot_disk_size`
* add some new arguments:
  * `instance_name  = "bastion-host"`
  * `network_tags   = ["bastion"]`
  * `allow_login    = true`
  * OPTIONAL `sa_description = "Manages permissions available to the VPC Bastion Host"`
* run `terraform plan`
  * it will show that a lot of states will be destroyed & created.
  * **DO NOT APPLY** this plan
* need to move the resoruce states to mitigate the proposed changes:
  * run `terraform state mv module.bastion_host.module.vm_instance module.bastion_host`
  * it will say `Successfully moved 2 object(s).`
* run `terraform plan` again
  * now it will say `No changes. Infrastructure is up-to-date.`
* DONE

# Upgrade guide from v2.4.0 to v2.5.0

First make sure you've planned & applied `v2.4.0`. Then, upon upgrading from `v2.4.0` to `v2.5.0`, you may (or may not) see a plan that destroys & creates an equal number of `*_iam_member` resources. It is OK to apply these changes as it only changes the IAM permissions from project-wide accesses to resource-specific accesses. Note that, after you plan & apply these changes, you may (or may not) get a **"Provider produced inconsistent result after apply"** error. Just re-plan and re-apply and that would resolve the error.

# Upgrade guide from v2.3.1 to v2.4.0

First make sure you've planned & applied `v2.3.1`. Then, upon upgrading from `v2.3.1` to `v2.4.0`, you may (or may not) see a plan that destroys & creates an equal number of `google_project_iam_member` resources. It is OK to apply these changes as it will only change the data-structure of these resources [from an array to a hashmap](https://github.com/airasia/terraform-google-external_access/wiki/The-problem-of-%22shifting-all-items%22-in-an-array). Note that, after you plan & apply these changes, you may (or may not) get a **"Provider produced inconsistent result after apply"** error. Just re-plan and re-apply and that would resolve the error.
