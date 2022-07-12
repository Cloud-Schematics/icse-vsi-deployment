##############################################################################
# Load Balancer Locals
##############################################################################

locals {
  load_balancers = flatten([
    var.create_public_load_balancer == true ? ["public"] : [],
    var.create_private_load_balancer == true ? ["private"] : []
  ])
}

##############################################################################

##############################################################################
# Create Load Balancers
##############################################################################

resource "ibm_is_lb" "lb" {
  for_each        = toset(local.load_balancers)
  name            = "${var.prefix}-${each.key}-lb"
  subnets         = var.subnet_zone_list.*.id
  type            = each.key
  security_groups = var.load_balancer_security_group_ids
  resource_group  = var.resource_group_id
  tags            = var.tags
}

##############################################################################

##############################################################################
# Create Load Balancer Back End Pools
##############################################################################

resource "ibm_is_lb_pool" "pool" {
  for_each       = toset(local.load_balancers)
  lb             = ibm_is_lb.lb[each.key].id
  name           = "${var.prefix}-${each.key}-lb-pool"
  algorithm      = var.pool_algorithm
  protocol       = var.pool_protocol
  health_delay   = var.pool_health_delay
  health_retries = var.pool_health_retries
  health_timeout = var.pool_health_timeout
  health_type    = var.pool_health_type
}

##############################################################################

##############################################################################
# Create Load Balancer Pool Members
##############################################################################

locals {
  pool_members = flatten([
    # For each load balancer
    for type in local.load_balancers :
    [
      # for each instance
      for instance in local.vsi_list :
      {
        name          = instance.name
        load_balancer = type
        conposed_name = "${type}-${instance.name}"
      }
    ]
  ])
}

resource "ibm_is_lb_pool_member" "pool_members" {
  for_each = {
    for pool_member in local.pool_members :
    (pool_member.conposed_name) => pool_member
  }
  port           = var.pool_member_port
  lb             = ibm_is_lb.lb[each.value.load_balancer].id
  pool           = element(split("/", ibm_is_lb_pool.pool[each.value.load_balancer].id), 1)
  target_address = module.vsi[each.value.name].primary_ipv4_address
}

##############################################################################

##############################################################################
# Load Balancer Listener
##############################################################################

resource "ibm_is_lb_listener" "listener" {
  for_each         = toset(local.load_balancers)
  lb               = ibm_is_lb.lb[each.key].id
  default_pool     = ibm_is_lb_pool.pool[each.key].id
  port             = var.listener_port
  protocol         = var.listener_protocol
  connection_limit = var.listener_connection_limit
  depends_on       = [ibm_is_lb_pool_member.pool_members] # Force pool members to attach before creation
}

##############################################################################