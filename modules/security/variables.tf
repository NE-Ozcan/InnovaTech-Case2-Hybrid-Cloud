variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "onprem_vpc_id" {
  type = string
}

variable "cloud_hub_vpc_id" {
  type = string
}

variable "onprem_cidr" {
  type = string
}

variable "cloud_hub_cidr" {
  type = string
}

variable "observability_subnet_cidr" {
  type = string
}

variable "soar_subnet_cidr" {
  type = string
}
