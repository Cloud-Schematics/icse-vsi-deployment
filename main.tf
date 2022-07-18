##############################################################################
# Get Image Using Data Block
##############################################################################

data "ibm_is_image" "image" {
  count = var.image_id == true ? 0 : 1
  name  = var.image_name
}

##############################################################################

##############################################################################
# Create map of total virtual servers to be created in the deployment
##############################################################################

locals {
  no_secondary_security_groups_created = (
    var.secondary_interface_security_groups == null
    || var.secondary_interface_security_groups == []
  )
  vsi_list = flatten([
    # For each subnet in the list. Use range to prevent error for values
    # not known until after apply
    for subnet in range(length(var.subnet_zone_list)) :
    [
      # For number of deployments
      for instance in range(var.vsi_per_subnet) :
      {
        name              = "${var.deployment_name}-${(subnet) * (var.vsi_per_subnet) + instance + 1}"
        zone              = var.subnet_zone_list[subnet].zone
        primary_subnet_id = var.subnet_zone_list[subnet].id
        secondary_subnets = [
          # For each interface in secondary subnets in the same zone as the primary network
          # interface
          for interface in var.secondary_subnet_zone_list :
          {
            name = interface.name
            id   = interface.id
            security_group_ids = (
              # if null or empty secondary and interface groups
              local.no_secondary_security_groups_created && (
                interface.security_group_ids == null
                || interface.security_group_ids == []
              )
              ? null
              # null if no secondary interface groups created by module and null group ids
              : local.no_secondary_security_groups_created && interface.security_group_ids != null
              # use only interface ids if not empty; null if empty
              ? (length(interface.security_group_ids) == 0 ? null : interface.security_group_ids)
              # otherwise concat with created groups
              : concat(
                # add empty group to list if null
                (interface.security_group_ids == null ? [] : interface.security_group_ids),
                module.secondary_network_interface_security_groups[interface.name].groups[0].id
              )
            )
          } if interface.zone == var.subnet_zone_list[subnet].zone
        ]
      }
    ]
  ])
}

##############################################################################

##############################################################################
# VSI
##############################################################################

module "vsi" {
  source = "github.com/Cloud-Schematics/icse-vsi-module"
  for_each = {
    for instance in local.vsi_list :
    (instance.name) => instance
  }
  image_id          = var.image_id == true ? var.image_name : data.ibm_is_image.image[0].id
  zone              = each.value.zone
  primary_subnet_id = each.value.primary_subnet_id
  name              = each.value.name
  secondary_subnets = each.value.secondary_subnets
  primary_security_group_ids = (
    # If both sg ids and not create sg
    var.primary_security_group_ids == null && var.primary_interface_security_group.create != true
    # null
    ? null
    # if no ids provided and create is true  
    : var.primary_security_group_ids == null
    # list with only created sg id
    ? [module.primary_network_security_group[0].groups[0].id]
    # otherwise combine lists
    : concat(
      var.primary_interface_security_group.create == true ? [module.primary_network_security_group[0].groups[0].id] : [],
      var.primary_security_group_ids
    )
  )
  boot_volume_encryption_key       = var.boot_volume_encryption_key
  prefix                           = var.prefix
  tags                             = var.tags
  resource_group_id                = var.resource_group_id
  vpc_id                           = var.vpc_id
  ssh_key_ids                      = var.ssh_key_ids
  profile                          = var.profile
  user_data                        = var.user_data
  allow_ip_spoofing                = var.allow_ip_spoofing
  add_floating_ip                  = var.add_floating_ip
  block_storage_volumes            = var.block_storage_volumes
  secondary_floating_ips           = var.secondary_floating_ips
  availability_policy_host_failure = var.availability_policy_host_failure
  boot_volume_name                 = var.boot_volume_name
  boot_volume_size                 = var.boot_volume_size
  dedicated_host                   = var.dedicated_host
  dedicated_host_group             = var.dedicated_host_group
  default_trusted_profile_target   = var.default_trusted_profile_target
  metadata_service_enabled         = var.metadata_service_enabled
  placement_group                  = var.placement_group
}

##############################################################################