output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}

output "appgw_name" {
  value = azurerm_application_gateway.appgw.name
}

output "appgw_frontend_ip_configuration" {
  value = azurerm_application_gateway.appgw.frontend_ip_configuration
}

output "appgw_frontend_port" {
  value = azurerm_application_gateway.appgw.frontend_port
}

output "appgw_gateway_ip_configuration" {
  value = azurerm_application_gateway.appgw.gateway_ip_configuration
}

output "appgw_http_listener" {
  value = azurerm_application_gateway.appgw.http_listener
}

output "appgw_backend_address_pool" {
  value = azurerm_application_gateway.appgw.backend_address_pool
}

output "appgw_backend_http_settings" {
  value = azurerm_application_gateway.appgw.backend_http_settings
}

output "appgw_request_routing_rule" {
  value = azurerm_application_gateway.appgw.request_routing_rule
}

output "appgw_sku" {
  value = azurerm_application_gateway.appgw.sku
}
