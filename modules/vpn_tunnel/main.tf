# ==============================================================================
# HYBRID CLOUD IPSEC SITE-TO-SITE VPN TUNNEL MODULE (INNOVATECH SOLUTIONS)
# ==============================================================================

# 1. Customer Gateway (Representeert On-Premises Firewall / Edge Router)
resource "aws_customer_gateway" "onprem_cgw" {
  bgp_asn    = 65000
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-cgw"
    Zone = "On-Premises-Perimeter"
  }
}

# 2. Site-to-Site VPN Connection (Dubbele redundante IPsec tunnels)
resource "aws_vpn_connection" "hybrid_vpn" {
  vpn_gateway_id      = var.vpn_gateway_id
  customer_gateway_id = aws_customer_gateway.onprem_cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  # Tunnel 1 Inside Network & Crypto Specificaties (IKEv2 & AES-256)
  tunnel1_inside_cidr                  = var.tunnel1_inside_cidr
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256", "AES256-GCM-16"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14, 19]
  tunnel1_phase2_encryption_algorithms = ["AES256", "AES256-GCM-16"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14, 19]
  tunnel1_dpd_timeout_action           = "restart"

  # Tunnel 2 Redundante Tunnel Specificaties (Design-for-Failure REQ-NCA-P2-01)
  tunnel2_inside_cidr                  = var.tunnel2_inside_cidr
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256", "AES256-GCM-16"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14, 19]
  tunnel2_phase2_encryption_algorithms = ["AES256", "AES256-GCM-16"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14, 19]
  tunnel2_dpd_timeout_action           = "restart"

  tags = {
    Name        = "${var.project_name}-${var.environment}-site-to-site-vpn"
    Description = "Versleutelde IPsec hybride route voor telemetrie en SOAR interactie"
  }
}

# 3. Statische VPN Route naar On-Premises CIDR
resource "aws_vpn_connection_route" "onprem" {
  destination_cidr_block = var.onprem_cidr
  vpn_connection_id      = aws_vpn_connection.hybrid_vpn.id
}
