output "vpn_connection_id" {
  description = "ID van de AWS Site-to-Site VPN verbinding"
  value       = aws_vpn_connection.hybrid_vpn.id
}

output "customer_gateway_id" {
  description = "ID van de geregistreerde Customer Gateway"
  value       = aws_customer_gateway.onprem_cgw.id
}

output "tunnel1_address" {
  description = "Publiek AWS IP-adres voor IPsec Tunnel 1"
  value       = aws_vpn_connection.hybrid_vpn.tunnel1_address
}

output "tunnel2_address" {
  description = "Publiek AWS IP-adres voor IPsec Tunnel 2"
  value       = aws_vpn_connection.hybrid_vpn.tunnel2_address
}

output "tunnel1_cgw_inside_address" {
  description = "Customer Gateway link-local IP voor Tunnel 1"
  value       = aws_vpn_connection.hybrid_vpn.tunnel1_cgw_inside_address
}

output "tunnel1_vgw_inside_address" {
  description = "AWS VGW link-local IP voor Tunnel 1"
  value       = aws_vpn_connection.hybrid_vpn.tunnel1_vgw_inside_address
}
