##############################################################################
# Module Variables
##############################################################################

variable "prefix" {
  description = "The prefix that you would like to prepend to your resources"
  type        = string
}

variable "tags" {
  description = "List of Tags for the resource created"
  type        = list(string)
  default     = null
}

variable "resource_group_id" {
  description = "Resource group ID for the VSI"
  type        = string
  default     = null
}

##############################################################################

##############################################################################
# VPC Variables
##############################################################################

variable "vpc_id" {
  description = "ID of the VPC where VSI will be provisioned"
  type        = string
}

variable "subnet_zone_list" {
  description = "List of subnets where the VSI deployment primary network interfaces will be created. This is intended to be an output from the ICSE Subnet Module or templates using it."
  type = list(
    object({
      name = string
      id   = string
      zone = string
      cidr = string
    })
  )
}

variable "vsi_per_subnet" {
  description = "Number of identical VSI to provision on each subnet"
  type        = number
  default     = 1
}

variable "ssh_key_ids" {
  description = "List of SSH Key Ids. At least one SSH key must be provided"
  type        = list(string)

  validation {
    error_message = "To provision VSI at least one VPC SSH Ket must be provided."
    condition     = length(var.ssh_key_ids) > 0
  }
}

##############################################################################

##############################################################################
# VSI Variables
##############################################################################

variable "deployment_name" {
  description = "Name of the VSI deployment. This will be used to dynamically configure server names."
  type        = string
  default     = "vsi"
}

variable "image_name" {
  description = "Name of the image to use for VSI. Use the command `ibmcloud is images` to find availabled images in your region."
  type        = string
  default     = "ibm-ubuntu-18-04-6-minimal-amd64-3"
}

variable "profile" {
  description = "Type of machine profile for VSI. Use the command `ibmcloud is instance-profiles` to find available profiles in your region"
  type        = string
  default     = "bx2-2x8"
}

variable "primary_security_group_ids" {
  description = "(Optional) List of security group ids to add to the primary network interface of each virtual server. Using an empty list will assign the default VPC security group."
  type        = list(string)
  default     = null

  validation {
    error_message = "Primary security group IDs should be either `null` or contain at least one security group."
    condition = (
      var.primary_security_group_ids == null
      ? true
      : length(var.primary_security_group_ids) > 0
    )
  }
}

variable "primary_interface_security_group" {
  description = "Object describing a security group to create for the primary interface,"
  type = object({
    create = bool
    rules = list(
      object({
        name      = string
        direction = string
        remote    = string
        tcp = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        udp = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        icmp = optional(
          object({
            type = number
            code = number
          })
        )
      })
    )
  })
  default = {
    create = false
    rules  = []
  }
}

##############################################################################

##############################################################################
# Optional VSI Variables
##############################################################################

variable "secondary_subnet_zone_list" {
  description = "(Optional) List of secondary subnets to use for VSI. For each secondary subnet in this list, a network interface will be attached to each VSI in the same zone."
  type = list(
    object({
      name               = string
      id                 = string
      zone               = string
      cidr               = string
      security_group_ids = optional(list(string))
    })
  )
  default = []
}

variable "secondary_interface_security_groups" {
  description = "(Optional) List of secondary interface security groups to create."
  type = list(
    object({
      subnet_name = string
      rules = list(
        object({
          name      = string
          direction = string
          remote    = string
          tcp = optional(
            object({
              port_max = number
              port_min = number
            })
          )
          udp = optional(
            object({
              port_max = number
              port_min = number
            })
          )
          icmp = optional(
            object({
              type = number
              code = number
            })
          )
        })
      )
    })
  )
  default = []
}

variable "boot_volume_encryption_key" {
  description = "(Optional) Boot volume encryption key to use for each server in the deployment."
  type        = string
  default     = null
}

variable "user_data" {
  description = "(Optional) Data to transfer to each server in the deployment."
  type        = string
  default     = null
}

variable "allow_ip_spoofing" {
  description = "Allow IP spoofing on primary network interface for each server in the deployment."
  type        = bool
  default     = false
}

variable "add_floating_ip" {
  description = "Add a floating IP to the primary network interface for each server in the deployment."
  type        = bool
  default     = false
}

variable "block_storage_volumes" {
  description = "List describing the block storage volumes that will be attached to each VSI. Storage volumes will be provisoned in the same resource group as the server instance."
  type = list(
    object({
      name                 = string           # Name of the storage volume
      profile              = string           # Profile to use for the volume
      capacity             = optional(number) # Capacity in gigabytes. If null, will default to `100`
      iops                 = optional(number) # The total input/ output operations per second (IOPS) for your storage. This value is required for custom storage profiles onli
      encryption_key       = optional(string) # ID of the key to use to encrypt volume
      delete_all_snapshots = optional(bool)   # Deletes all snapshots created from this volume.
    })
  )
  default = []

  validation {
    error_message = "Each block storage volume must have a unique name."
    condition     = length(distinct(var.block_storage_volumes.*.name)) == length(var.block_storage_volumes)
  }
}

##############################################################################

##############################################################################
# Uncommon Optional Variables
##############################################################################

variable "secondary_floating_ips" {
  description = "List of secondary interfaces to add floating ips"
  type        = list(string)
  default     = []

  validation {
    error_message = "Secondary floating IPs must contain a unique list of interfaces."
    condition     = length(var.secondary_floating_ips) == length(distinct(var.secondary_floating_ips))
  }
}

variable "availability_policy_host_failure" {
  description = "(Optional) The availability policy to use for each virtual server instance. The action to perform if the compute host experiences a failure. Supported values are `restart` and `stop`."
  type        = string
  default     = null

  validation {
    error_message = "Availability Policy Host Failure can be `null`, `stop`, or `restart`."
    condition = (
      var.availability_policy_host_failure == null
      ? true
      : contains(["stop", "restart"], var.availability_policy_host_failure)
    )
  }
}

variable "boot_volume_name" {
  description = "(Optional) Suffix to add to each boot volume. Format <var.prefix>-<var.deployment_name>-<suffix>-<vsi count>."
  type        = string
  default     = null
}

variable "boot_volume_size" {
  description = "(Optional) The size of the boot volume for each instance.(The capacity of the volume in gigabytes. This defaults to minimum capacity of the image and maximum to 250"
  type        = number
  default     = null
}


variable "dedicated_host" {
  description = "(Optional) The placement restrictions to use for each virtual server instance. Unique ID of the dedicated host where the instance id placed."
  type        = string
  default     = null
}

variable "dedicated_host_group" {
  description = "(Optional) The placement restrictions to use for each virtual server instance. Unique ID of the dedicated host group where the instance is placed."
  type        = string
  default     = null
}

variable "default_trusted_profile_target" {
  description = "(Optional) The unique identifier or CRN of the default IAM trusted profile to use for each virtual server instance."
  type        = string
  default     = null
}

variable "metadata_service_enabled" {
  description = "(Optional) Indicates whether the metadata service endpoint is available to each virtual server instance. Default value : false"
  type        = bool
  default     = null
}

variable "placement_group" {
  description = "(Optional) Unique Identifier of the Placement Group for restricting the placement of each instance"
  type        = string
  default     = null
}

##############################################################################

##############################################################################
# Load Balancer Variables
##############################################################################

variable "create_public_load_balancer" {
  description = "Connect each VSI instance with a single public load balancer."
  type        = bool
  default     = false
}

variable "create_private_load_balancer" {
  description = "Connect each VSI instance with a single private load balancer."
  type        = bool
  default     = false
}

variable "load_balancer_security_group_ids" {
  description = "List of security group IDs to attach Load Balancers."
  type        = list(string)
  default     = null

  validation {
    error_message = "Value must be either null or contain at least one entry."
    condition = (
      var.load_balancer_security_group_ids == null
      ? true
      : length(var.load_balancer_security_group_ids) > 0
    )
  }
}

variable "pool_algorithm" {
  description = "Algorithm for load blancer back end pools"
  type        = string
  default     = "round_robin"

  validation {
    error_message = "Load Balancer Pool algorithm can only be `round_robin`, `weighted_round_robin`, or `least_connections`."
    condition     = contains(["round_robin", "weighted_round_robin", "least_connections"], var.pool_algorithm)
  }
}
variable "pool_protocol" {
  description = "Protocol for load blancer back end pools"
  type        = string
  default     = "http"

  validation {
    error_message = "Load Balancer Pool Protocol can only be `http`, `https`, or `tcp`."
    condition     = contains(["http", "https", "tcp"], var.pool_protocol)
  }
}

variable "pool_health_delay" {
  description = "Health delay for load blancer back end pools. Must be greater than pool health timeout value."
  type        = number
  default     = 60
}
variable "pool_health_retries" {
  description = "Health retries for load blancer back end pools"
  type        = number
  default     = 5
}

variable "pool_health_timeout" {
  description = "Health timeout for load blancer back end pools. Must be less than pool health delay."
  type        = number
  default     = 30
}
variable "pool_health_type" {
  description = "health type for load blancer back end pools"
  type        = string
  default     = "http"

  validation {
    error_message = "Load Balancer Pool health type can only be `http`, `https`, or `tcp`."
    condition     = contains(["http", "https", "tcp"], var.pool_health_type)
  }
}

variable "pool_member_port" {
  description = "Port for back end pool."
  type        = number
  default     = 8080
}

variable "listener_port" {
  description = "The listener port number. Valid range 1 to 65535."
  type        = number
  default     = 80

  validation {
    error_message = "Listerner port number can be from 1 to 65535."
    condition     = var.listener_port > 0 && var.listener_port <= 65535
  }
}

variable "listener_protocol" {
  description = " The listener protocol. Enumeration type are http, tcp, https and udp. Network load balancer supports only tcp and udp protocol."
  type        = string
  default     = "http"

  validation {
    error_message = "Load Balancer listener protocol type can only be `http`, `https`, `udp`, or `tcp`."
    condition     = contains(["http", "https", "tcp", "udp"], var.listener_protocol)
  }
}

variable "listener_connection_limit" {
  description = "The connection limit of the listener. Valid range is 1 to 15000. Network load balancer do not support connection_limit argument."
  type        = number
  default     = null

  validation {
    error_message = "Connection limit must be between 1 and 15000."
    condition = (
      var.listener_connection_limit == null
      ? true
      : var.listener_connection_limit > 0 && var.listener_connection_limit <= 15000
    )
  }
}

##############################################################################