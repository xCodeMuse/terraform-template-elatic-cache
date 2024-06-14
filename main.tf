locals {

  # port               = var.engine == "memcached" ? 11211 : 6379

  tags = merge(var.tags, { terraform-aws-modules = "elasticache" })

  create_replication_group = {
    for key, elastic_cluster in var.elastic_clusters: key => elastic_cluster
    if elastic_cluster.create_replication_group && !(elastic_cluster.create_primary_global_replication_group || elastic_cluster.create_secondary_global_replication_group)
  }
  
  create_global_replication_group = {
    for key, elastic_cluster in var.elastic_clusters: key => elastic_cluster
    if elastic_cluster.create_replication_group && (elastic_cluster.create_primary_global_replication_group || elastic_cluster.create_secondary_global_replication_group)
  }

  create_primary_global_replication_group = {
    for key, elastic_cluster in var.elastic_clusters: key => elastic_cluster
    if elastic_cluster.create_replication_group && elastic_cluster.create_primary_global_replication_group
  }

  create_parameter_group = {
   for key, elastic_cluster in var.elastic_clusters: key => elastic_cluster
    if elastic_cluster.create_parameter_group
  }

  create_subnet_group = {
    for key, elastic_cluster in var.elastic_clusters: key => elastic_cluster
      if elastic_cluster.create_subnet_group
  }
}

################################################################################
# Cluster
################################################################################

resource "aws_elasticache_cluster" "elastic_cluster" {
  for_each = var.elastic_clusters

  apply_immediately          = each.value.apply_immediately
  auto_minor_version_upgrade = each.value.auto_minor_version_upgrade
  availability_zone          = each.value.availability_zone
  az_mode                    = each.value.replication_group_id != null ? null : each.value.az_mode
  cluster_id                 = each.value.cluster_id
  engine                     = each.value.engine
  engine_version             = each.value.replication_group_id != null ? null : each.value.engine_version
  final_snapshot_identifier  = each.value.final_snapshot_identifier
  ip_discovery               = each.value.ip_discovery

  dynamic "log_delivery_configuration" {
    for_each = { for k, v in each.value.log_delivery_configuration : k => v if each.value.engine != "memcached" }

    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = try(log_delivery_configuration.value.log_type, log_delivery_configuration.key)
    }
  }

  maintenance_window           = each.value.replication_group_id != null ? null : each.value.maintenance_window
  network_type                 = each.value.network_type
  node_type                    = each.value.replication_group_id != null ? null : each.value.node_type
  notification_topic_arn       = each.value.replication_group_id != null ? null : each.value.notification_topic_arn
  num_cache_nodes              = each.value.replication_group_id != null ? null : each.value.num_cache_nodes
  outpost_mode                 = each.value.outpost_mode
  parameter_group_name         = each.value.replication_group_id != null ? null : each.value.create_parameter_group ? aws_elasticache_parameter_group.ec_parameter_group[each.key].id : each.value.parameter_group_name
  port                         = each.value.replication_group_id != null ? null : each.value.port
  preferred_availability_zones = each.value.preferred_availability_zones
  preferred_outpost_arn        = each.value.preferred_outpost_arn
  replication_group_id         = each.value.create_replication_group ? aws_elasticache_replication_group.replica_group[each.key].id : each.value.replication_group_id
  security_group_ids           = each.value.replication_group_id != null ? null : each.value.security_group_ids
  snapshot_arns                = each.value.replication_group_id != null ? null : each.value.snapshot_arns
  snapshot_name                = each.value.replication_group_id != null ? null : each.value.snapshot_name
  snapshot_retention_limit     = each.value.replication_group_id != null ? null : each.value.snapshot_retention_limit
  snapshot_window              = each.value.replication_group_id != null ? null : each.value.snapshot_window
  subnet_group_name            = each.value.replication_group_id != null ? null : each.value.create_subnet_group ? aws_elasticache_subnet_group.subnet_group[each.key].name : each.value.subnet_group_name
  transit_encryption_enabled   = each.value.engine == "memcached" ? each.value.transit_encryption_enabled : null

  tags = local.tags
}

################################################################################
# Replication Group
################################################################################

resource "aws_elasticache_replication_group" "replica_group" {
  for_each = local.create_replication_group

  apply_immediately           = each.value.apply_immediately
  at_rest_encryption_enabled  = each.value.replica_group.at_rest_encryption_enabled
  auth_token                  = each.value.replica_group.auth_token
  auth_token_update_strategy  = each.value.replica_group.auth_token_update_strategy
  auto_minor_version_upgrade  = each.value.auto_minor_version_upgrade
  automatic_failover_enabled  = each.value.replica_group.multi_az_enabled || each.value.replica_group.cluster_mode_enabled ? true : each.value.replica_group.automatic_failover_enabled
  data_tiering_enabled        = each.value.replica_group.data_tiering_enabled
  description                 = coalesce(each.value.description, "Replication group")
  engine                      = each.value.engine
  engine_version              = each.value.engine_version
  final_snapshot_identifier   = each.value.final_snapshot_identifier
  global_replication_group_id = each.value.replica_group.global_replication_group_id
  ip_discovery                = each.value.replica_group.ip_discovery
  kms_key_id                  = each.value.replica_group.at_rest_encryption_enabled ? each.value.replica_group.kms_key_arn : null

  dynamic "log_delivery_configuration" {
    for_each = { for k, v in each.value.log_delivery_configuration : k => v if each.value.engine == "redis" }

    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = try(log_delivery_configuration.value.log_type, log_delivery_configuration.key)
    }
  }

  maintenance_window          = each.value.maintenance_window
  multi_az_enabled            = each.value.replica_group.multi_az_enabled
  network_type                = each.value.network_type
  node_type                   = each.value.node_type
  notification_topic_arn      = each.value.notification_topic_arn
  num_cache_clusters          = each.value.replica_group.cluster_mode_enabled ? null : each.value.replica_group.num_cache_clusters
  num_node_groups             = each.value.replica_group.cluster_mode_enabled ? each.value.replica_group.num_node_groups : null
  parameter_group_name        = each.value.create_parameter_group ? aws_elasticache_parameter_group.ec_parameter_group[each.key].id : each.value.parameter_group_name
  port                        = each.value.port
  preferred_cache_cluster_azs = each.value.replica_group.preferred_cache_cluster_azs
  replicas_per_node_group     = each.value.replica_group.replicas_per_node_group
  replication_group_id        = each.value.replication_group_id
  security_group_names        = each.value.replica_group.security_group_names
  security_group_ids          = each.value.security_group_ids
  snapshot_arns               = each.value.snapshot_arns
  snapshot_name               = each.value.snapshot_name
  snapshot_retention_limit    = each.value.snapshot_retention_limit
  snapshot_window             = each.value.snapshot_window
  subnet_group_name           = each.value.create_subnet_group ? aws_elasticache_subnet_group.subnet_group[each.key].name : each.value.subnet_group_name
  transit_encryption_enabled  = each.value.transit_encryption_enabled
  user_group_ids              = each.value.replica_group.user_group_ids

  tags = local.tags
}

################################################################################
# Global Replication Group
################################################################################

resource "aws_elasticache_global_replication_group" "global_replication_group" {
  for_each = local.create_primary_global_replication_group

  automatic_failover_enabled = each.value.replica_group.automatic_failover_enabled
  cache_node_type            = each.value.node_type
  engine_version             = each.value.engine_version

  global_replication_group_id_suffix   = each.value.replication_group_id
  global_replication_group_description = coalesce(each.value.description, "Global replication group")
  primary_replication_group_id         = aws_elasticache_replication_group.global[each.key].id
  parameter_group_name                 = each.value.create_parameter_group ? aws_elasticache_parameter_group.ec_parameter_group[each.key].id : each.value.parameter_group_name
}

resource "aws_elasticache_replication_group" "global" {
  for_each = local.create_global_replication_group

  apply_immediately           = each.value.apply_immediately
  at_rest_encryption_enabled  = each.value.create_secondary_global_replication_group ? null : each.value.replica_group.at_rest_encryption_enabled
  auth_token                  = each.value.replica_group.auth_token
  auth_token_update_strategy  = each.value.replica_group.auth_token_update_strategy
  auto_minor_version_upgrade  = each.value.auto_minor_version_upgrade
  automatic_failover_enabled  = each.value.replica_group.multi_az_enabled || each.value.replica_group.cluster_mode_enabled ? true : each.value.replica_group.automatic_failover_enabled
  data_tiering_enabled        = each.value.replica_group.data_tiering_enabled
  description                 = coalesce(each.value.description, "Global replication group")
  engine                      = each.value.create_secondary_global_replication_group ? null : each.value.engine
  engine_version              = each.value.create_secondary_global_replication_group ? null : each.value.engine_version
  final_snapshot_identifier   = each.value.final_snapshot_identifier
  global_replication_group_id = each.value.create_secondary_global_replication_group ? each.value.replica_group.global_replication_group_id : null
  ip_discovery                = each.value.ip_discovery
  kms_key_id                  = each.value.replica_group.at_rest_encryption_enabled ? each.value.replica_group.kms_key_arn : null

  dynamic "log_delivery_configuration" {
    for_each = { for k, v in each.value.log_delivery_configuration : k => v if each.value.engine != "memcached" }

    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = try(log_delivery_configuration.value.log_type, log_delivery_configuration.key)
    }
  }

  maintenance_window          = each.value.maintenance_window
  multi_az_enabled            = each.value.replica_group.multi_az_enabled
  network_type                = each.value.network_type
  node_type                   = each.value.node_type
  notification_topic_arn      = each.value.notification_topic_arn
  num_cache_clusters          = each.value.replica_group.cluster_mode_enabled ? null : each.value.replica_group.num_cache_clusters
  num_node_groups             = each.value.create_secondary_global_replication_group ? null : each.value.replica_group.cluster_mode_enabled ? each.value.replica_group.num_node_groups : null
  parameter_group_name        = each.value.create_secondary_global_replication_group ? null : each.value.create_parameter_group ? aws_elasticache_parameter_group.ec_parameter_group[each.key].id : each.value.parameter_group_name
  port                        = each.value.port
  preferred_cache_cluster_azs = each.value.replica_group.preferred_cache_cluster_azs
  replicas_per_node_group     = each.value.replica_group.replicas_per_node_group
  replication_group_id        = each.value.replication_group_id
  security_group_names        = each.value.create_secondary_global_replication_group ? null : each.value.replica_group.security_group_names
  security_group_ids          = each.value.security_group_ids
  snapshot_arns               = each.value.create_secondary_global_replication_group ? null : each.value.snapshot_arns
  snapshot_name               = each.value.create_secondary_global_replication_group ? null : each.value.snapshot_name
  snapshot_retention_limit    = each.value.snapshot_retention_limit
  snapshot_window             = each.value.snapshot_window
  subnet_group_name           = each.value.create_subnet_group ? aws_elasticache_subnet_group.subnet_group[each.key].name : each.value.subnet_group_name
  transit_encryption_enabled  = each.value.create_secondary_global_replication_group ? null : each.value.transit_encryption_enabled
  user_group_ids              = each.value.replica_group.user_group_ids

  tags = local.tags

  lifecycle {
    ignore_changes = [each.value.engine_version]
  }
}


################################################################################
# Parameter Group
################################################################################

resource "aws_elasticache_parameter_group" "ec_parameter_group" {
  for_each = local.create_parameter_group

  description = coalesce(each.value.parameter_group_description, "ElastiCache parameter group")
  family      = each.value.parameter_group_family
  name        = each.value.parameter_group_name

  dynamic "parameter" {
    for_each = each.value.replica_group.cluster_mode_enabled ? concat([{ name = "cluster-enabled", value = "yes" }], each.value.parameters) : each.value.parameters

    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Subnet Group
################################################################################

resource "aws_elasticache_subnet_group" "subnet_group" {
  for_each = local.create_subnet_group

  name        = try(coalesce(each.value.subnet_group_name, each.value.cluster_id, each.value.replication_group_id), "")
  description = coalesce(each.value.subnet_group_description, "ElastiCache subnet group")
  subnet_ids  = each.value.subnet_ids

  tags = local.tags
}
