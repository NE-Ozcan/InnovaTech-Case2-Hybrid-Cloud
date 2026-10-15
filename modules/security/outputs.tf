output "onprem_gateway_sg_id" {
  description = "Security Group ID van de On-Premises Gateway"
  value       = aws_security_group.onprem_gateway_sg.id
}

output "observability_sg_id" {
  description = "Security Group ID van de Observability Stack"
  value       = aws_security_group.observability_sg.id
}

output "soar_sg_id" {
  description = "Security Group ID van het Geïsoleerde SOAR Platform"
  value       = aws_security_group.soar_sg.id
}
