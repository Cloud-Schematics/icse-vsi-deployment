# ICSE VSI Deployment Module

Deploy VSI using the same template across any number of subnets in a single VPC. Optionally create public and/or private load balancers for your deployment.

---

## Table of Contents

1. [Virtual Servers](#virtual-servers)
    - [Virtual Server Variables](#virtual-server-variables)
    - [Optional Virtual Server Variables](#virtual-server-variables)
2. [Load Balancers](#load-balancers)
3. [Module Outputs](#module-outputs)

---

## Virtual Servers

This module uses the [ICSE VSI Module](https://github.com/Cloud-Schematics/icse-vsi-module) to create virtual servers, block storage volumes, and optionally floating IPs.

Each virtual server will share the same image, user data, resource group, and profile.

---

### Virtual Server Variables

Name                       | Type                                                                      | Description                                                                                                                                                                            | Sensitive | Default
-------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ----------------------------------
vpc_id                     | string                                                                    | ID of the VPC where VSI will be provisioned                                                                                                                                            |           | 
subnet_zone_list           | list( object({ name = string id = string zone = string cidr = string }) ) | List of subnets where the VSI deployment primary network interfaces will be created. This is intended to be an output from the ICSE Subnet Module or templates using it.               |           | 
ssh_key_ids                | list(string)                                                              | List of SSH Key Ids. At least one SSH key must be provided                                                                                                                             |           | 
vsi_per_subnet             | number                                                                    | Number of identical VSI to provision on each subnet                                                                                                                                    |           | 1
deployment_name            | string                                                                    | Name of the VSI deployment. This will be used to dynamically configure server names.                                                                                                   |           | vsi
image_name                 | string                                                                    | Name of the image to use for VSI. Use the command `ibmcloud is images` to find availabled images in your region. Use this variable to provide image ID if `image_id` is set to `true`. |           | ibm-ubuntu-18-04-6-minimal-amd64-3
image_id                   | bool                                                                      | Use when providing image ID in `image_name` rather than the image name. This will prevent the lookup of image name from data.                                                          |           | false
profile                    | string                                                                    | Type of machine profile for VSI. Use the command `ibmcloud is instance-profiles` to find available profiles in your region                                                             |           | bx2-2x8
primary_security_group_ids | list(string)                                                              | (Optional) List of security group ids to add to the primary network interface of each virtual server. Using an empty list will assign the default VPC security group.                  |           | null

---

### Optional Virtual Server Variables

Name                             | Type                                                                                                                                                                           | Description                                                                                                                                                                             | Sensitive | Default
-------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------
secondary_subnet_zone_list       | list( object({ name = string id = string zone = string cidr = string security_group_ids = optional(list(string)) }) )                                                          | List of secondary subnets to use for VSI. For each secondary subnet in this list, a network interface will be attached to each VSI in the same zone.                                    |           | []
boot_volume_encryption_key       | string                                                                                                                                                                         | (Optional) Boot volume encryption key to use for each server in the deployment.                                                                                                         |           | null
user_data                        | string                                                                                                                                                                         | (Optional) Data to transfer to each server in the deployment.                                                                                                                           |           | null
allow_ip_spoofing                | bool                                                                                                                                                                           | Allow IP spoofing on primary network interface for each server in the deployment.                                                                                                       |           | false
add_floating_ip                  | bool                                                                                                                                                                           | Add a floating IP to the primary network interface for each server in the deployment.                                                                                                   |           | false
block_storage_volumes            | list( object({ name = string profile = string capacity = optional(number) iops = optional(number) encryption_key = optional(string) delete_all_snapshots = optional(bool) }) ) | List describing the block storage volumes that will be attached to each VSI. Storage volumes will be provisoned in the same resource group as the server instance.                      |           | []
secondary_floating_ips           | list(string)                                                                                                                                                                   | List of secondary interfaces to add floating ips                                                                                                                                        |           | []
availability_policy_host_failure | string                                                                                                                                                                         | (Optional) The availability policy to use for each virtual server instance. The action to perform if the compute host experiences a failure. Supported values are `restart` and `stop`. |           | null
boot_volume_name                 | string                                                                                                                                                                         | (Optional) Suffix to add to each boot volume. Format `<var.prefix>-<var.deployment_name>-<suffix>-<vsi count>`.                                                                         |           | null
boot_volume_size                 | number                                                                                                                                                                         | (Optional) The size of the boot volume for each instance.(The capacity of the volume in gigabytes. This defaults to minimum capacity of the image and maximum to 250                    |           | null
dedicated_host                   | string                                                                                                                                                                         | (Optional) The placement restrictions to use for each virtual server instance. Unique ID of the dedicated host where the instance id placed.                                            |           | null
dedicated_host_group             | string                                                                                                                                                                         | (Optional) The placement restrictions to use for each virtual server instance. Unique ID of the dedicated host group where the instance is placed.                                      |           | null
default_trusted_profile_target   | string                                                                                                                                                                         | (Optional) The unique identifier or CRN of the default IAM trusted profile to use for each virtual server instance.                                                                     |           | null
metadata_service_enabled         | bool                                                                                                                                                                           | (Optional) Indicates whether the metadata service endpoint is available to each virtual server instance. Default value : false                                                          |           | null
placement_group                  | string                                                                                                                                                                         | (Optional) Unique Identifier of the Placement Group for restricting the placement of each instance                                                                                      |           | null

---

## Load Balancers

Users can optionall create a public and/or private load balancer connecting each instance managed by this module.

### Load Balancer Variables

Name                             | Type         | Description                                                                                                                      | Sensitive | Default
-------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------- | --------- | -----------
create_public_load_balancer      | bool         | Connect each VSI instance with a single public load balancer.                                                                    |           | false
create_private_load_balancer     | bool         | Connect each VSI instance with a single private load balancer.                                                                   |           | false
load_balancer_security_group_ids | list(string) | List of security group IDs to attach Load Balancers.                                                                             |           | null
pool_algorithm                   | string       | Algorithm for load blancer back end pools                                                                                        |           | round_robin
pool_protocol                    | string       | Protocol for load blancer back end pools                                                                                         |           | http
pool_health_delay                | number       | Health delay for load blancer back end pools. Must be greater than pool health timeout value.                                    |           | 60
pool_health_retries              | number       | Health retries for load blancer back end pools                                                                                   |           | 5
pool_health_timeout              | number       | Health timeout for load blancer back end pools. Must be less than pool health delay.                                             |           | 30
pool_health_type                 | string       | health type for load blancer back end pools                                                                                      |           | http
pool_member_port                 | number       | Port for back end pool.                                                                                                          |           | 8080
listener_port                    | number       | The listener port number. Valid range 1 to 65535.                                                                                |           | 80
listener_protocol                | string       | The listener protocol. Enumeration type are http, tcp, https and udp. Network load balancer supports only tcp and udp protocol.  |           | http
listener_connection_limit        | number       | The connection limit of the listener. Valid range is 1 to 15000. Network load balancer do not support connection_limit argument. |           | null

---

## Module Outputs

Name                  | Description
--------------------- | ----------------------------------------------------------------------------------------
virtual_servers       | List of VSI IDs, Names, Primary IPV4 addresses, floating IPs, and secondary floating IPs
public_load_balancer  | Public Load Balancer data
private_load_balancer | Private Load Balancer data
