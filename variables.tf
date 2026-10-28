variable "autoscale_configuration" {
  description = "The name of the application gateway."
  type        = object({
    min_capacity = number
    max_capacity = number
  })
}

variable "backend_address_pools" {
  description = "The backend address pool configuration for the application gateway. Each pool can target IP addresses, FQDNs, or both."
  type = list(object({
    name = string
    fqdns = optional(list(string))
    ip_addresses = optional(list(string))
  }))
}

variable "backend_http_settings" {
  description = "The backend HTTP settings configuration for the application gateway."
  type = list(object({
    protocol = string
    name = string
    port = string
    cookie_based_affinity = optional(string, "Disabled")
    path = optional(string, "/")
    request_timeout = optional(number, 20)
    probe_name = optional(string)
    host_name = optional(string)
    pick_host_name_from_backend_address = optional(bool, false)
  }))
}

variable "enable_http2" {
  description = "Whether HTTP/2 support is enabled for the application gateway."
  type        = bool
  default     = true
}

variable "environment" {
  description = "The environment for the application gateway (e.g., dev, int, crt, prod)."
  type        = string
}

variable "frontend_ip_configuration" {
  description = "The frontend IP configuration(s) for the application gateway. Standard_v2/WAF_v2 SKUs require at least one public frontend IP configuration (public_ip_address_id set); a private one may be added alongside it."
  type = list(object({
    name = string
    private_ip_address = optional(string)
    private_ip_address_allocation = optional(string)
    subnet_id = optional(string)
    public_ip_address_id = optional(string)
  }))
}

variable "frontend_port" {
  description = "The frontend port configuration(s) for the application gateway."
  type = list(object({
    name = string
    port = string
  }))
}

variable "gateway_ip_configuration" {
  description = "The gateway IP configuration for the application gateway."
  type = object({
    name = optional(string, "appGatewayIpConfig")
    subnet_id = string
  })
}

variable "http_listener" {
  description = "The HTTP listener configuration(s) for the application gateway. Listeners sharing the same frontend_ip_configuration_name and frontend_port_name must either all be Basic (host_names unset, at most one such listener per pair) or all be Multi-site (host_names set on each)."
  type = list(object({
    name = optional(string, "listener")
    frontend_ip_configuration_name = string
    frontend_port_name = string
    protocol = string
    ssl_certificate_name = optional(string)
    host_names = optional(list(string))
  }))
}

variable "identity" {
  description = "Managed identity assigned to the application gateway. Required when any ssl_certificates entry references a Key Vault secret."
  type = object({
    type         = string
    identity_ids = list(string)
  })
  default = null
}

variable "location" {
  description = "The Azure region where the application gateway will be deployed."
  type        = string
}

variable "probes" {
  description = "Custom health probes for the application gateway. Reference an entry by name from a backend_http_settings entry's probe_name."
  type = list(object({
    name = string
    protocol = string
    path = optional(string, "/")
    interval = optional(number, 30)
    timeout = optional(number, 30)
    unhealthy_threshold = optional(number, 3)
    host = optional(string)
    port = optional(number)
    pick_host_name_from_backend_http_settings = optional(bool, true)
  }))
  default = []
}

variable "redirect_configurations" {
  description = "Redirect configurations for the application gateway. Reference an entry by name from a request_routing_rules entry's redirect_configuration_name."
  type = list(object({
    name = string
    redirect_type = optional(string, "Permanent")
    target_listener_name = string
    include_path = optional(bool, true)
    include_query_string = optional(bool, true)
  }))
  default = []
}

variable "request_routing_rules" {
  description = "The request routing rule configuration for the application gateway. Each rule must set either both backend_address_pool_name and backend_http_settings_name, or redirect_configuration_name."
  type = list(object({
    http_listener_name = string
    name = string
    rule_type = string
    priority = number
    backend_address_pool_name = optional(string)
    backend_http_settings_name = optional(string)
    redirect_configuration_name = optional(string)
  }))
}

variable "resource_group_name" {
  description = "The name of the resource group where the application gateway will be deployed."
  type        = string
}

variable "sku" {
  description = "The SKU configuration for the application gateway."
  type = object({
    name = string
    tier = string
  })
}

variable "solution_name" {
  description = "The name of the solution or project that the application gateway is part of."
  type        = string
}

variable "ssl_certificates" {
  description = "SSL certificates available to the application gateway. Reference an entry by name from an http_listener's ssl_certificate_name when protocol = \"Https\"."
  type = list(object({
    name                 = string
    key_vault_secret_id = string
  }))
  default = []
}
