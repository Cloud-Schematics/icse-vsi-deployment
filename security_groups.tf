##############################################################################
# Primary Network Interface Security Group
##############################################################################

module "primary_network_security_group" {
  source = "github.com/Cloud-Schematics/vpc-security-group-module"
  count             = var.primary_interface_security_group.create == true ? 1 : 0
  prefix            = var.prefix
  tags              = var.tags
  vpc_id            = var.vpc_id
  resource_group_id = var.resource_group_id
  security_groups = [
    {
      name  = each.value.name
      rules = each.value.rules
    }
  ]
}

##############################################################################

##############################################################################
# Groups for Secondary Network Interfaces
##############################################################################

module "secondary_network_interface_security_groups" {
  source = "github.com/Cloud-Schematics/vpc-security-group-module"
  for_each = {
    for group in var.secondary_network_interface_security_groups :
    (group.subnet_name) => group
  }
  prefix            = var.prefix
  tags              = var.tags
  vpc_id            = var.vpc_id
  resource_group_id = var.resource_group_id
  security_groups = [
    {
      name  = "${var.deployment_name}-${each.value.name}"
      rules = each.value.rules
    }
  ]
}

##############################################################################