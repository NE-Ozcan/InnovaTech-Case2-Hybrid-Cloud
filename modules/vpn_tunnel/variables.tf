variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpn_gateway_id" {
  description = "Virtual Private Gateway ID van de AWS Cloud Hub"
  type        = string
}

variable "customer_gateway_ip" {
  description = "Publiek IP-adres van de On-Premises Gateway / Firewall"
  type        = string
}

variable "onprem_cidr" {
  description = "CIDR block van het On-Premises netwerk (voor statische VPN routing)"
  type        = string
}

variable "tunnel1_inside_cidr" {
  description = "Link-local inside CIDR voor tunnel 1"
  type        = string
}

variable "tunnel2_inside_cidr" {
  description = "Link-local inside CIDR voor redundante tunnel 2"
  type        = string
}
