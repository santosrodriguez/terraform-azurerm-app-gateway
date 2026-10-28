terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
    random = {
      source = "hashicorp/random"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "random_string" "suffix" {
  length = 4
  upper = false
  numeric = true
  special = false
  lower = false
}

data "azurecaf_name" "appgw_name" {
  resource_type = "azurerm_application_gateway"
  suffixes = [var.solution_name, var.location, var.environment, random_string.suffix.result]
}

resource "azurerm_application_gateway" "appgw" {
  name = data.azurecaf_name.appgw_name.result
  resource_group_name = var.resource_group_name
  location = var.location
  enable_http2 = var.enable_http2
  autoscale_configuration {
    min_capacity = var.autoscale_configuration.min_capacity
    max_capacity = var.autoscale_configuration.max_capacity
  }
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                 = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules != null ? var.request_routing_rules : []
    content {
      http_listener_name = request_routing_rule.value.http_listener_name
      name = request_routing_rule.value.name
      rule_type = request_routing_rule.value.rule_type
      priority = request_routing_rule.value.priority
      backend_address_pool_name = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
    }
  }
  dynamic "redirect_configuration" {
    for_each = var.redirect_configurations
    content {
      name                  = redirect_configuration.value.name
      redirect_type         = redirect_configuration.value.redirect_type
      target_listener_name  = redirect_configuration.value.target_listener_name
      include_path          = redirect_configuration.value.include_path
      include_query_string  = redirect_configuration.value.include_query_string
    }
  }
  dynamic "probe" {
    for_each = var.probes
    content {
      name                                       = probe.value.name
      protocol                                    = probe.value.protocol
      path                                        = probe.value.path
      interval                                    = probe.value.interval
      timeout                                     = probe.value.timeout
      unhealthy_threshold                         = probe.value.unhealthy_threshold
      host                                        = probe.value.host
      port                                        = probe.value.port
      pick_host_name_from_backend_http_settings   = probe.value.pick_host_name_from_backend_http_settings
    }
  }
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools != null ? var.backend_address_pools : []
    content {
      name = backend_address_pool.value.name
      fqdns = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }
  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configuration
    content {
      name = frontend_ip_configuration.value.name
      private_ip_address = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
      subnet_id = frontend_ip_configuration.value.subnet_id
      public_ip_address_id = frontend_ip_configuration.value.public_ip_address_id
    }
  }
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings != null ? var.backend_http_settings : []
    content {
      protocol = backend_http_settings.value.protocol
      name = backend_http_settings.value.name
      port = backend_http_settings.value.port
      cookie_based_affinity = backend_http_settings.value.cookie_based_affinity
      path = backend_http_settings.value.path
      request_timeout = backend_http_settings.value.request_timeout
      probe_name = backend_http_settings.value.probe_name
      host_name = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
    }
  }
  gateway_ip_configuration {
    name = var.gateway_ip_configuration.name
    subnet_id = var.gateway_ip_configuration.subnet_id
  }
  dynamic "frontend_port" {
    for_each = var.frontend_port
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }
  sku {
    name = var.sku.name
    tier = var.sku.tier
  }
  dynamic "http_listener" {
    for_each = var.http_listener
    content {
      name = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name = http_listener.value.frontend_port_name
      protocol = http_listener.value.protocol
      ssl_certificate_name = http_listener.value.ssl_certificate_name
      host_names = http_listener.value.host_names
    }
  }
}
