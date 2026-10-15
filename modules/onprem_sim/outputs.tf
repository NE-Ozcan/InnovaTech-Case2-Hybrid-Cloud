output "vpc_id" {
  description = "VPC ID van het on-premises netwerk"
  value       = aws_vpc.onprem.id
}

output "cidr_block" {
  description = "CIDR block van het on-premises netwerk"
  value       = aws_vpc.onprem.cidr_block
}

output "gateway_subnet_id" {
  description = "Subnet ID voor de on-premises edge gateway"
  value       = aws_subnet.gateway.id
}

output "workstation_subnet_id" {
  description = "Subnet ID voor de gemonitorde werkstations"
  value       = aws_subnet.workstations.id
}

output "server_subnet_id" {
  description = "Subnet ID voor lokale servers"
  value       = aws_subnet.servers.id
}

output "customer_gateway_ip" {
  description = "Publiek IP-adres van de On-Premises Customer Gateway (Firewall)"
  value       = aws_eip.cgw_eip.public_ip
}

output "internal_route_table_id" {
  description = "Route Table ID voor de interne on-premises subnets"
  value       = aws_route_table.internal.id
}
