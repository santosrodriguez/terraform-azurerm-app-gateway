# terraform-azurerm-cpd-app-gateway

Terraform module for provisioning an **Azure Application Gateway** within the CareSource Cloud Platform and Delivery (CPD) environment. Generates a CAF-compliant resource name automatically using the solution name, location, and environment.

> **Note:** Listeners, ports, backend pools, backend HTTP settings, and routing rules are all list inputs — add or remove entries and re-apply to update the gateway. These blocks are fully managed by Terraform; changes made outside Terraform (e.g. in the Azure portal) will be reverted on the next apply.

---

## Usage

```hcl
module "app_gateway" {
  source  = "<module-registry>/azurerm/app-gateway"
  version = "~> 1.0"

  solution_name       = "<solution-name>"
  environment         = "<environment>"
  location            = "<azure-region>"
  resource_group_name = "<resource-group-name>"

  sku = {
    name = "<sku-name>"
    tier = "<sku-tier>"
  }

  autoscale_configuration = {
    min_capacity = "<min-capacity>"
    max_capacity = "<max-capacity>"
  }

  gateway_ip_configuration = {
    subnet_id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name>/subnets/<subnet-name>"
  }

  # Standard_v2/WAF_v2 SKUs require at least one public frontend IP configuration
  # (public_ip_address_id set). A private one can optionally be added alongside it.
  frontend_ip_configuration = [
    {
      name                 = "<public-frontend-ip-name>"
      public_ip_address_id = "<public-ip-resource-id>"
    },
    {
      name                          = "<private-frontend-ip-name>"
      private_ip_address            = "<private-ip-address>"
      private_ip_address_allocation = "Static"
      subnet_id                     = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name>/subnets/<subnet-name>"
    }
  ]

  frontend_port = [
    {
      name = "<frontend-port-name>"
      port = "<port-number>"
    }
  ]

  http_listener = [
    {
      name                            = "<listener-name>"
      frontend_ip_configuration_name = "<private-frontend-ip-name>"
      frontend_port_name             = "<frontend-port-name>"
      protocol                       = "<protocol>"
      # Only required when protocol = "Https"; must match a name in ssl_certificates.
      ssl_certificate_name           = "<ssl-certificate-name>"
    }
  ]

  # Only needed for Https listeners. Each entry's key_vault_secret_id points at
  # a certificate stored in Key Vault as a secret (PFX). The gateway's identity
  # (below) must have permission to read that secret.
  ssl_certificates = [
    {
      name                 = "<ssl-certificate-name>"
      key_vault_secret_id = "<key-vault-secret-id-or-versionless-id>"
    }
  ]

  # Required when any ssl_certificates entry is set. Use a user-assigned
  # identity that's been granted access to the Key Vault holding the cert.
  identity = {
    type         = "UserAssigned"
    identity_ids = ["<user-assigned-identity-resource-id>"]
  }

  # Each pool can target IP addresses, FQDNs, or both.
  backend_address_pools = [
    {
      name         = "<backend-pool-name>"
      ip_addresses = ["<backend-ip-address>"]
      fqdns        = ["<backend-fqdn>"]
    }
  ]

  probes = [
    {
      name     = "<probe-name>"
      protocol = "<protocol>"
      path     = "/"
    }
  ]

  backend_http_settings = [
    {
      name       = "<http-settings-name>"
      protocol   = "<protocol>"
      port       = "<port-number>"
      probe_name = "<probe-name>"
      # Overrides the Host header sent to the backend. Leave unset to pass
      # through the client's original Host header.
      host_name  = "<backend-host-header>"
    }
  ]

  # Basic rules must set either (backend_address_pool_name AND
  # backend_http_settings_name) OR redirect_configuration_name — not both.
  request_routing_rules = [
    {
      name                       = "<routing-rule-name>"
      rule_type                  = "<rule-type>"
      priority                   = "<priority-number>"
      http_listener_name         = "<listener-name>"
      backend_address_pool_name  = "<backend-pool-name>"
      backend_http_settings_name = "<http-settings-name>"
    },
    {
      name                         = "<redirect-rule-name>"
      rule_type                    = "<rule-type>"
      priority                     = "<priority-number>"
      http_listener_name           = "<http-listener-name>"
      redirect_configuration_name  = "<redirect-configuration-name>"
    }
  ]

  # Used by the redirect rule above, e.g. to send an Http listener to its
  # Https counterpart.
  redirect_configurations = [
    {
      name                  = "<redirect-configuration-name>"
      redirect_type         = "Permanent"
      target_listener_name  = "<https-listener-name>"
    }
  ]

  enable_http2 = true
}

# Add another hostname/site later by appending another entry to each of the
# lists above (frontend_port, http_listener, backend_address_pools, probes,
# backend_http_settings, request_routing_rules) with unique names.
```
---

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `solution_name` | `string` | Yes | — | Solution or project name; used in CAF resource naming |
| `environment` | `string` | Yes | — | Deployment environment (e.g. `dev`, `int`, `crt`, `prod`) |
| `location` | `string` | Yes | — | Azure region (e.g. `eastus2`) |
| `resource_group_name` | `string` | Yes | — | Resource group to deploy the gateway into |
| `sku` | `object` | Yes | — | SKU `name` and `tier`. Capacity is controlled entirely via `autoscale_configuration` — Standard_v2/WAF_v2 SKUs do not allow a fixed `capacity` alongside autoscaling |
| `autoscale_configuration` | `object` | Yes | — | `min_capacity` and `max_capacity` for autoscaling |
| `gateway_ip_configuration` | `object` | Yes | `name = "appGatewayIpConfig"` | `subnet_id` for the gateway subnet |
| `frontend_ip_configuration` | `list(object)` | Yes | — | One entry per frontend IP: `name`, optional `subnet_id`, `private_ip_address`, `private_ip_address_allocation`, and `public_ip_address_id`. Standard_v2/WAF_v2 SKUs require at least one entry with `public_ip_address_id` set; a private entry can be added alongside it |
| `frontend_port` | `list(object)` | Yes | — | One entry per frontend port: `name` and `port` number |
| `http_listener` | `list(object)` | Yes | `name = "listener"` | One entry per listener: `name`, `frontend_ip_configuration_name`, `frontend_port_name`, `protocol`, and optional `ssl_certificate_name` (required when `protocol = "Https"`, must match a name in `ssl_certificates`) |
| `backend_address_pools` | `list(object)` | Yes | — | One entry per backend pool: `name`, optional `ip_addresses` list, optional `fqdns` list. A pool may set either or both |
| `probes` | `list(object)` | No | `[]` | One entry per custom health probe: `name`, `protocol`, optional `path` (`/`), `interval` (30s), `timeout` (30s), `unhealthy_threshold` (3), `host`, `port`, and `pick_host_name_from_backend_http_settings` (`true`) |
| `backend_http_settings` | `list(object)` | Yes | `cookie_based_affinity = "Disabled"`, `path = "/"`, `request_timeout = 20` | One entry per settings profile: `name`, `protocol`, `port`, `cookie_based_affinity`, `path`, `request_timeout`, optional `probe_name` (matches a name in `probes`), optional `host_name` (overrides the Host header sent to the backend), and optional `pick_host_name_from_backend_address` |
| `request_routing_rules` | `list(object)` | Yes | — | One entry per routing rule: `name`, `rule_type`, `priority`, `http_listener_name`, and either (`backend_address_pool_name` + `backend_http_settings_name`) or `redirect_configuration_name` |
| `redirect_configurations` | `list(object)` | No | `[]` | One entry per redirect, referenced from a rule's `redirect_configuration_name`: `name`, optional `redirect_type` (`Permanent`), `target_listener_name`, optional `include_path` (`true`), optional `include_query_string` (`true`) |
| `ssl_certificates` | `list(object)` | No | `[]` | One entry per certificate available to Https listeners: `name` and `key_vault_secret_id`. Requires `identity` to be set |
| `identity` | `object` | No | `null` | Managed identity assigned to the gateway: `type` (e.g. `"UserAssigned"`) and `identity_ids`. Required when `ssl_certificates` is non-empty, so the gateway can read the Key Vault secret |
| `enable_http2` | `bool` | No | `true` | Whether HTTP/2 support is enabled on the gateway |

---

## Outputs

| Name | Description |
|------|-------------|
| `appgw_id` | Resource ID of the Application Gateway |
| `appgw_name` | CAF-generated name of the Application Gateway |
| `appgw_frontend_ip_configuration` | Frontend IP configuration block |
| `appgw_frontend_port` | Frontend port configuration block |
| `appgw_gateway_ip_configuration` | Gateway IP configuration block |
| `appgw_http_listener` | HTTP listener configuration block |
| `appgw_backend_address_pool` | Backend address pool configuration block |
| `appgw_backend_http_settings` | Backend HTTP settings block |
| `appgw_request_routing_rule` | Request routing rule block |
| `appgw_sku` | SKU configuration block |
