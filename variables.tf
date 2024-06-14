################################################################################
# Cluster
################################################################################
variable "elastic_clusters" {
  description = "A map of all elastic clusters"
  type = map(object({
    apply_immediately = optional(bool)
    auto_minor_version_upgrade = optional(bool)
    availability_zone = string
    az_mode = optional(string)
    cluster_id = string
    engine = optional(string)
    engine_version = optional(string)
    final_snapshot_identifier = optional(string)
    ip_discovery = optional(string)
    log_delivery_configuration = optional(map(object({
      destination_type = string
      log_format = optional(string)
      log_type = string
    })))
    maintenance_window = optional(string)
    network_type  = optional(string)
    node_type = optional(string)
    notification_topic_arn = optional(string)
    num_cache_nodes = optional(number)
    outpost_mode = optional(string)
    parameter_group_name = optional(string)
    port = optional(number)
    preferred_availability_zones = optional(list(string))
    preferred_outpost_arn = optional(string)
    replication_group_id = optional(string)
    security_group_ids = optional(list(string))
    snapshot_arns = optional(list(string))
    snapshot_name = optional(string)
    snapshot_retention_limit = optional(number)
    snapshot_window = optional(string)
    subnet_group_name = optional(string)
    transit_encryption_enabled = optional(bool)
    create_replication_group = optional(bool)
    replica_group = optional(object({
      at_rest_encryption_enabled = optional(bool)
      auth_token = optional(string)
      auth_token_update_strategy = optional(string)
      automatic_failover_enabled = optional(bool)
      data_tiering_enabled = optional(bool)
      description = optional(string)
      global_replication_group_id = optional(string)
      ip_discovery = optional(string)
      kms_key_id = optional(string)
      multi_az_enabled = optional(bool)
      num_cache_clusters = optional(number)
      num_node_groups = optional(number)
      preferred_cache_cluster_azs = optional(list(string))
      replicas_per_node_group = optional(number)
      security_group_names = optional(list(string))
      user_group_ids = optional(list(string))
      cluster_mode_enabled = optional(bool)
      kms_key_arn = optional(string)
    }))
    create_primary_global_replication_group = optional(bool)
    create_secondary_global_replication_group = optional(bool)
    create_parameter_group = optional(bool)
    parameter_group_description = optional(string)
    parameter_group_family = string
    create_subnet_group = optional(bool)
    subnet_group_description = optional(string)
    subnet_ids = optional(list(string))
    parameters = optional(list(map(string)))
  }))
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}