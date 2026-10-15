# ==============================================================================
# INNOVATECH SOLUTIONS - CASE 2 HYBRID CLOUD & VPN TUNNEL VARIABLES
# ==============================================================================

variable "aws_region" {
  description = "AWS regio voor de Cloud Hub VPC infrastructuur"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Omgevingsnaam (bijv. development, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project prefix voor naamgeving en tagging van alle resources"
  type        = string
  default     = "innovatech"
}

# --- On-Premises Simulatie Netwerkparameters (RFC 1918) ---
variable "onprem_cidr" {
  description = "CIDR block voor het gesimuleerde On-Premises netwerk (kantoor & lokale servers)"
  type        = string
  default     = "192.168.0.0/16"
}

variable "onprem_workstation_subnet_cidr" {
  description = "Subnet voor interne endpoints en werkstations die gemonitord worden"
  type        = string
  default     = "192.168.1.0/24"
}

variable "onprem_server_subnet_cidr" {
  description = "Subnet voor lokale applicatieservers en logbronnen"
  type        = string
  default     = "192.168.10.0/24"
}

variable "onprem_gateway_subnet_cidr" {
  description = "Subnet voor de on-premises edge router / firewall / customer gateway"
  type        = string
  default     = "192.168.0.0/24"
}

# --- AWS Cloud Hub Netwerkparameters (RFC 1918 - Niet-overlappend) ---
variable "cloud_hub_cidr" {
  description = "CIDR block voor de centrale AWS Cloud Hub VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "cloud_hub_ingress_subnet_cidr" {
  description = "Publiek ingress subnet voor routing, transit en beheerinterfaces"
  type        = string
  default     = "10.10.1.0/24"
}

variable "cloud_hub_observability_subnet_cidr" {
  description = "Privé subnet voor de centrale Observability stack (Prometheus, Loki, Grafana)"
  type        = string
  default     = "10.10.10.0/24"
}

variable "cloud_hub_soar_subnet_cidr" {
  description = "Strikt geïsoleerd privé subnet voor het event-driven SOAR automatiseringsplatform"
  type        = string
  default     = "10.10.20.0/24"
}

# --- IPsec VPN Tunnel Parameters (RFC 3927 Link-Local) ---
variable "vpn_tunnel1_inside_cidr" {
  description = "Link-local inside CIDR voor IPsec Tunnel 1 (/30 bereik)"
  type        = string
  default     = "169.254.10.0/30"
}

variable "vpn_tunnel2_inside_cidr" {
  description = "Link-local inside CIDR voor redundante IPsec Tunnel 2 (/30 bereik)"
  type        = string
  default     = "169.254.11.0/30"
}
