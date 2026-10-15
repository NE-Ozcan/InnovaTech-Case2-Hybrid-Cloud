# ==============================================================================
# ZERO-TRUST SECURITY GROUPS MODULE (INNOVATECH SOLUTIONS)
# ==============================================================================

# 1. Security Group voor On-Premises Edge Gateway / Firewall
resource "aws_security_group" "onprem_gateway_sg" {
  name        = "${var.project_name}-${var.environment}-onprem-gateway-sg"
  description = "Toestaat van IPsec IKE en NAT-T verkeer voor de hybride VPN tunnel"
  vpc_id      = var.onprem_vpc_id

  # IKE (Internet Key Exchange)
  ingress {
    description = "IPsec IKE UDP 500"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NAT-Traversal
  ingress {
    description = "IPsec NAT-T UDP 4500"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Encapsulating Security Payload (ESP)
  ingress {
    description = "IPsec ESP Protocol 50"
    from_port   = 0
    to_port     = 0
    protocol    = "50"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-gateway-sg"
  }
}

# 2. Security Group voor Observability Stack (PLG: Prometheus, Loki, Grafana)
# REQ-NCA-P2-03: Geen directe publieke exposure, uitsluitend via private VPN routes
resource "aws_security_group" "observability_sg" {
  name        = "${var.project_name}-${var.environment}-observability-sg"
  description = "Inname van logs en metrics via de beveiligde hybride route"
  vpc_id      = var.cloud_hub_vpc_id

  # Logbron 1: Syslog (Netwerk- & Firewall-logs)
  ingress {
    description = "Centrale Syslog UDP 514 van On-Premises en Hub"
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = [var.onprem_cidr, var.cloud_hub_cidr]
  }

  ingress {
    description = "Centrale Syslog TCP 514 van On-Premises en Hub"
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr, var.cloud_hub_cidr]
  }

  # Logbron 2: Loki Ingestion API
  ingress {
    description = "Grafana Loki Log Push API (Promtail/FluentBit)"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr, var.cloud_hub_cidr]
  }

  # Prometheus Telemetrie Scrapes
  ingress {
    description = "Prometheus Server & Node Exporter Metrics"
    from_port   = 9090
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr, var.cloud_hub_cidr]
  }

  # Grafana Dashboard (Alleen intern via VPN bereikbaar)
  ingress {
    description = "Grafana Web Dashboard via VPN"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr]
  }

  # Egress naar SOAR Platform (Alerting Webhooks)
  egress {
    description = "Webhook Alerts naar Geisoleerd SOAR platform"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = [var.soar_subnet_cidr]
  }

  # Generieke interne egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cloud_hub_cidr]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-observability-sg"
  }
}

# 3. Security Group voor Geïsoleerd SOAR Platform (Strikte Platformscheiding)
# REQ-NCA-P2-08: Gemonitorde endpoints mogen NIET op hetzelfde platform draaien
resource "aws_security_group" "soar_sg" {
  name        = "${var.project_name}-${var.environment}-soar-isolated-sg"
  description = "Strikt geisoleerde rule engine voor security responses"
  vpc_id      = var.cloud_hub_vpc_id

  # Inkomende alert triggers: UITSLUITEND vanuit het Observability Subnet
  ingress {
    description = "Alert Webhook van Grafana/Prometheus Alertmanager"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = [var.observability_subnet_cidr]
  }

  # Uitgaande Geautomatiseerde Actie 1: Firewall API call (IP-Block)
  egress {
    description = "Geautomatiseerde Actie 1: REST API call naar On-Premises Firewall"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr]
  }

  # Uitgaande Geautomatiseerde Actie 2: Notificaties / Incident Alerts (Email / Slack / SNS)
  egress {
    description = "Geautomatiseerde Actie 2: Externe incident notificatie via HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-soar-isolated-sg"
  }
}
