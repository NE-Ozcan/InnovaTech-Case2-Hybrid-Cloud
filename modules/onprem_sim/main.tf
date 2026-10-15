# ==============================================================================
# ON-PREMISES SIMULATIE NETWERK MODULE (INNOVATECH SOLUTIONS)
# ==============================================================================

# 1. On-Premises VPC (Simulatie lokaal kantoornetwerk)
resource "aws_vpc" "onprem" {
  cidr_block           = var.onprem_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-vpc"
    Zone = "On-Premises"
  }
}

# 2. Subnetten (Segmentatie: Edge Gateway, Werkstations, Servers)
resource "aws_subnet" "gateway" {
  vpc_id                  = aws_vpc.onprem.id
  cidr_block              = var.gateway_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-gateway-subnet"
    Type = "Perimeter"
  }
}

resource "aws_subnet" "workstations" {
  vpc_id            = aws_vpc.onprem.id
  cidr_block        = var.workstation_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-workstations-subnet"
    Type = "Monitored-Endpoints"
  }
}

resource "aws_subnet" "servers" {
  vpc_id            = aws_vpc.onprem.id
  cidr_block        = var.server_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-servers-subnet"
    Type = "Local-Servers-LogSource"
  }
}

# 3. Internet Gateway (WAN-simulatie voor Edge Router)
resource "aws_internet_gateway" "onprem_igw" {
  vpc_id = aws_vpc.onprem.id

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-igw"
  }
}

# 4. Elastic IP voor Customer Gateway (Publiek IP van On-Premises Firewall)
resource "aws_eip" "cgw_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-cgw-eip"
  }
}

# 5. Route Tables
resource "aws_route_table" "gateway" {
  vpc_id = aws_vpc.onprem.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.onprem_igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-gateway-rt"
  }
}

resource "aws_route_table" "internal" {
  vpc_id = aws_vpc.onprem.id

  tags = {
    Name = "${var.project_name}-${var.environment}-onprem-internal-rt"
  }
}

# 6. Route Table Associations
resource "aws_route_table_association" "gateway" {
  subnet_id      = aws_subnet.gateway.id
  route_table_id = aws_route_table.gateway.id
}

resource "aws_route_table_association" "workstations" {
  subnet_id      = aws_subnet.workstations.id
  route_table_id = aws_route_table.internal.id
}

resource "aws_route_table_association" "servers" {
  subnet_id      = aws_subnet.servers.id
  route_table_id = aws_route_table.internal.id
}

data "aws_availability_zones" "available" {
  state = "available"
}
