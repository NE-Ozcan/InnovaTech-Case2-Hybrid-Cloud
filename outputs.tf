# ==============================================================================
# INNOVATECH SOLUTIONS - CASE 2 ROOT OUTPUT VARIABLES
# ==============================================================================

# On-Premises Outputs
output "onprem_vpc_id" {
  description = "VPC ID van het on-premises netwerk"
  value       = module.onprem_sim.vpc_id
}

output "onprem_customer_gateway_public_ip" {
  description = "Publiek IP-adres van de On-Premises Firewall/Gateway"
  value       = module.onprem_sim.customer_gateway_ip
}

# Cloud Hub Outputs
output "cloud_hub_vpc_id" {
  description = "VPC ID van de centrale AWS Cloud Hub"
  value       = module.cloud_hub.vpc_id
}

output "cloud_hub_vpn_gateway_id" {
  description = "VGW ID van de AWS Cloud Hub"
  value       = module.cloud_hub.vpn_gateway_id
}

output "observability_subnet_id" {
  description = "Subnet ID voor de centrale Observability stack (PLG)"
  value       = module.cloud_hub.observability_subnet_id
}

output "soar_isolated_subnet_id" {
  description = "Subnet ID voor het geïsoleerde SOAR platform (REQ-NCA-P2-08)"
  value       = module.cloud_hub.soar_subnet_id
}

# VPN Tunnel Outputs
output "vpn_connection_id" {
  description = "AWS Site-to-Site VPN Verbinding ID"
  value       = module.vpn_tunnel.vpn_connection_id
}

output "vpn_tunnel1_public_ip" {
  description = "Publiek AWS Endpoint IP voor IPsec Tunnel 1"
  value       = module.vpn_tunnel.tunnel1_address
}

output "vpn_tunnel2_public_ip" {
  description = "Publiek AWS Endpoint IP voor redundante IPsec Tunnel 2 (Design-for-Failure)"
  value       = module.vpn_tunnel.tunnel2_address
}

output "vpn_tunnel1_inside_cgw_ip" {
  description = "Inside link-local IP voor Customer Gateway (Tunnel 1)"
  value       = module.vpn_tunnel.tunnel1_cgw_inside_address
}

output "vpn_tunnel1_inside_vgw_ip" {
  description = "Inside link-local IP voor AWS VGW (Tunnel 1)"
  value       = module.vpn_tunnel.tunnel1_vgw_inside_address
}

# Security Outputs
output "observability_security_group_id" {
  description = "Security Group ID voor de Observability stack"
  value       = module.security.observability_sg_id
}

output "soar_security_group_id" {
  description = "Security Group ID voor het geïsoleerde SOAR platform"
  value       = module.security.soar_sg_id
}
