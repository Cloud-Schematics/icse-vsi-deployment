##############################################################################
# VSI Outputs
##############################################################################

output "virtual_servers" {
  description = "List of VSI IDs, Names, Primary IPV4 addresses, floating IPs, and secondary floating IPs"
  value = [
    for instance in module.vsi :
    {
      id                     = instance.id
      name                   = instance.name
      primary_ipv4_address   = instance.primary_ipv4_address
      floating_ip            = instance.floating_ip
      secondary_floating_ips = instance.secondary_floating_ips
    }
  ]
}

##############################################################################

##############################################################################
# Load Balancer Outputs
##############################################################################

output "public_load_balancer" {
  description = "Public Load Balancer data"
  value = (
    !contains(local.load_balancers, "public")
    ? null
    : {
      id          = ibm_is_lb.lb["public"].id
      crn         = ibm_is_lb.lb["public"].crn
      hostname    = ibm_is_lb.lb["public"].hostname
      public_ips  = ibm_is_lb.lb["public"].public_ips
      private_ips = ibm_is_lb.lb["public"].private_ips
    }
  )
}

output "private_load_balancer" {
  description = "Private Load Balancer data"
  value = (
    !contains(local.load_balancers, "private")
    ? null
    : {
      id          = ibm_is_lb.lb["private"].id
      crn         = ibm_is_lb.lb["private"].crn
      hostname    = ibm_is_lb.lb["private"].hostname
      public_ips  = ibm_is_lb.lb["private"].public_ips
      private_ips = ibm_is_lb.lb["private"].private_ips
    }
  )
}


##############################################################################