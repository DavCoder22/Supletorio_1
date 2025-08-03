# Outputs para la región primaria
output "primary_region_alb_dns" {
  description = "DNS del ALB en la región primaria (${var.primary_region})"
  value       = module.primary_region.alb_dns_name
}

output "primary_region_vpc_id" {
  description = "ID de la VPC en la región primaria"
  value       = module.primary_region.vpc_id
}

output "primary_region_subnet_ids" {
  description = "IDs de las subredes en la región primaria"
  value       = module.primary_region.subnet_ids
}

# Outputs para la región secundaria
output "secondary_region_alb_dns" {
  description = "DNS del ALB en la región secundaria (${var.secondary_region})"
  value       = module.secondary_region.alb_dns_name
}

output "secondary_region_vpc_id" {
  description = "ID de la VPC en la región secundaria"
  value       = module.secondary_region.vpc_id
}

output "secondary_region_subnet_ids" {
  description = "IDs de las subredes en la región secundaria"
  value       = module.secondary_region.subnet_ids
}

# Información general
output "primary_region" {
  description = "Región primaria configurada"
  value       = var.primary_region
}

output "secondary_region" {
  description = "Región secundaria configurada"
  value       = var.secondary_region
}

# Instrucciones de conexión
output "connection_instructions" {
  description = "Instrucciones para conectarse a la aplicación"
  value = <<EOT

  ¡Despliegue en múltiples regiones completado!

  Acceso a la aplicación:
  - Región primaria (${var.primary_region}): http://${module.primary_region.alb_dns_name}
  - Región secundaria (${var.secondary_region}): http://${module.secondary_region.alb_dns_name}

  Para configurar el balanceo de carga global, configura un registro CNAME en tu DNS que apunte a:
  ${module.primary_region.alb_dns_name}

  Monitorea el estado de las regiones con los siguientes endpoints de salud:
  - Primaria: http://${module.primary_region.alb_dns_name}/health
  - Secundaria: http://${module.secondary_region.alb_dns_name}/health
  EOT
}
