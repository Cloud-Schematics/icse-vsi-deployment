##############################################################################
# Fail States
##############################################################################

locals {
  CONFIGURATION_FAILURE_pool_health_delay_must_be_greater_than_timeout = regex(
    "true",
    var.pool_health_delay > var.pool_health_timeout
  )
}

##############################################################################