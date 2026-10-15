# ==============================================================================
# INNOVATECH SOLUTIONS - CASE 2 HYBRID CLOUD & VPN TUNNEL ROOT ORCHESTRATION
# ==============================================================================

# 1. On-Premises Netwerk Module (Simulatie Kantoor, Werkstations en Servers)
module "onprem_sim" {
  source = "./modules/onprem_sim"

  project_name            = var.project_name
  environment             = var.environment
  onprem_cidr             = var.onprem_cidr
  gateway_subnet_cidr     = var.onprem_gateway_subnet_cidr
  workstation_subnet_cidr = var.onprem_workstation_subnet_cidr
  server_subnet_cidr      = var.onprem_server_subnet_cidr
  cloud_hub_cidr          = var.cloud_hub_cidr
}

# 2. AWS Cloud Hub VPC Module (Centrale Ingress, Observability & SOAR Spokes)
module "cloud_hub" {
  source = "./modules/cloud_hub"

  project_name              = var.project_name
  environment               = var.environment
  cloud_hub_cidr            = var.cloud_hub_cidr
  ingress_subnet_cidr       = var.cloud_hub_ingress_subnet_cidr
  observability_subnet_cidr = var.cloud_hub_observability_subnet_cidr
  soar_subnet_cidr          = var.cloud_hub_soar_subnet_cidr
  onprem_cidr               = var.onprem_cidr
}

# 3. IPsec Site-to-Site VPN Tunnel Module (Hybride Versleutelde Route)
module "vpn_tunnel" {
  source = "./modules/vpn_tunnel"

  project_name        = var.project_name
  environment         = var.environment
  vpn_gateway_id      = module.cloud_hub.vpn_gateway_id
  customer_gateway_ip = module.onprem_sim.customer_gateway_ip
  onprem_cidr         = var.onprem_cidr
  tunnel1_inside_cidr = var.vpn_tunnel1_inside_cidr
  tunnel2_inside_cidr = var.vpn_tunnel2_inside_cidr
}

# 4. Zero-Trust Security Module (Network Isolation & Policy Enforcement)
module "security" {
  source = "./modules/security"

  project_name              = var.project_name
  environment               = var.environment
  onprem_vpc_id             = module.onprem_sim.vpc_id
  cloud_hub_vpc_id          = module.cloud_hub.vpc_id
  onprem_cidr               = var.onprem_cidr
  cloud_hub_cidr            = var.cloud_hub_cidr
  observability_subnet_cidr = var.cloud_hub_observability_subnet_cidr
  soar_subnet_cidr          = var.cloud_hub_soar_subnet_cidr
}
