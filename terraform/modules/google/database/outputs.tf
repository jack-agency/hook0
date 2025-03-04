output "db_connection_string" {
  value       = "postgresql://${var.db_user}:${var.db_password}@127.0.0.1/${var.db_name}"
  sensitive   = true
  description = "Database connection string"
}

output "instance_name" {
  value       = module.cloud_sql.instance_name
  description = "Cloud SQL instance name"
}

output "instance_connection_name" {
  value       = module.cloud_sql.instance_connection_name
  description = "The connection name of the master instance to be used in connection strings"
}

output "private_ip" {
  value       = module.cloud_sql.private_ip_address
  description = "Private IP of Cloud SQL instance"
}
