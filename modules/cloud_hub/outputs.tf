output "vpc_id" {
  description = "VPC ID van de AWS Cloud Hub"
  value       = aws_vpc.hub.id
}

output "cidr_block" {
  description = "CIDR block van de AWS Cloud Hub"
  value       = aws_vpc.hub.cidr_block
}

output "ingress_subnet_id" {
  description = "Subnet ID voor Ingress / Transit"
  value       = aws_subnet.ingress.id
}

output "observability_subnet_id" {
  description = "Subnet ID voor Observability Spoke (PLG stack)"
  value       = aws_subnet.observability.id
}

output "soar_subnet_id" {
  description = "Subnet ID voor Geïsoleerd SOAR Spoke"
  value       = aws_subnet.soar.id
}

output "vpn_gateway_id" {
  description = "Virtual Private Gateway ID voor VPN tunnel terminatie"
  value       = aws_vpn_gateway.hub_vgw.id
}

output "observability_route_table_id" {
  description = "Route Table ID voor Observability Subnet"
  value       = aws_route_table.observability.id
}

output "soar_route_table_id" {
  description = "Route Table ID voor SOAR Subnet"
  value       = aws_route_table.soar.id
}
