output "db_connection_string" {
  value       = "postgresql://${var.db_user}:${var.db_password}@${module.cloud_sql.private_ip_address}:5432/${var.db_name}"
  sensitive   = true
  description = "Database connection string"
}

output "instance_name" {
  value       = module.cloud_sql.instance_name
  description = "Cloud SQL instance name"
}

output "private_ip" {
  value       = module.cloud_sql.private_ip_address
  description = "Private IP of Cloud SQL instance"
}
