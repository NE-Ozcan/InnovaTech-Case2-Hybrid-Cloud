# ==============================================================================
# AWS CLOUD HUB VPC MODULE (INNOVATECH SOLUTIONS)
# ==============================================================================

# 1. Cloud Hub VPC (Centrale Netwerkhub, Transit & Spoke Isolatie)
resource "aws_vpc" "hub" {
  cidr_block           = var.cloud_hub_cidr
  enable_dns_hostnames = true # REQ-NCA-P2-04: Interne DNS Resolution
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-cloud-hub-vpc"
    Zone = "Cloud-Hub"
  }
}

# 2. Subnetten (Segmentatie Hub, Observability Spoke & Geïsoleerd SOAR Spoke)
resource "aws_subnet" "ingress" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = var.ingress_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-hub-ingress-subnet"
    Type = "Ingress-Transit"
  }
}

resource "aws_subnet" "observability" {
  vpc_id            = aws_vpc.hub.id
  cidr_block        = var.observability_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-${var.environment}-hub-observability-subnet"
    Type = "Observability-Spoke"
  }
}

resource "aws_subnet" "soar" {
  vpc_id            = aws_vpc.hub.id
  cidr_block        = var.soar_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-${var.environment}-hub-soar-isolated-subnet"
    Type = "SOAR-Isolated-Spoke" # REQ-NCA-P2-08: Strikte platformscheiding
  }
}

# 3. Internet Gateway (voor Ingress & Externe API respons)
resource "aws_internet_gateway" "hub_igw" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "${var.project_name}-${var.environment}-hub-igw"
  }
}

# 4. Virtual Private Gateway (VGW voor VPN Tunnel Terminatie)
resource "aws_vpn_gateway" "hub_vgw" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "${var.project_name}-${var.environment}-hub-vgw"
  }
}

# 5. Route Tables
resource "aws_route_table" "ingress" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub_igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-hub-ingress-rt"
  }
}

resource "aws_route_table" "observability" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "${var.project_name}-${var.environment}-hub-observability-rt"
  }
}

resource "aws_route_table" "soar" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "${var.project_name}-${var.environment}-hub-soar-rt"
  }
}

# 6. Route Table Associations
resource "aws_route_table_association" "ingress" {
  subnet_id      = aws_subnet.ingress.id
  route_table_id = aws_route_table.ingress.id
}

resource "aws_route_table_association" "observability" {
  subnet_id      = aws_subnet.observability.id
  route_table_id = aws_route_table.observability.id
}

resource "aws_route_table_association" "soar" {
  subnet_id      = aws_subnet.soar.id
  route_table_id = aws_route_table.soar.id
}

# 7. VPN Route Propagation (Automatische injectie van On-Premises routes via VGW)
resource "aws_vpn_gateway_route_propagation" "observability" {
  vpn_gateway_id = aws_vpn_gateway.hub_vgw.id
  route_table_id = aws_route_table.observability.id
}

resource "aws_vpn_gateway_route_propagation" "soar" {
  vpn_gateway_id = aws_vpn_gateway.hub_vgw.id
  route_table_id = aws_route_table.soar.id
}

data "aws_availability_zones" "available" {
  state = "available"
}
