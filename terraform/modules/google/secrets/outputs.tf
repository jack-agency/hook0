## Cloud SQL Database.

output "db_password_secret" {
  sensitive   = true
  description = "Value of the database password secret"
  value       = google_secret_manager_secret_version.db_password_version.secret_data
}

output "db_password_secret_id" {
  description = "ID of the database password secret"
  value       = google_secret_manager_secret.db_password.id
}

output "db_user_secret" {
  sensitive   = true
  description = "Value of the database user secret"
  value       = google_secret_manager_secret_version.db_user_version.secret_data
}

output "db_user_secret_id" {
  description = "ID of the database user secret"
  value       = google_secret_manager_secret.db_user.id
}

output "db_connection_string" {
  sensitive   = true
  description = "Database connection string"
  value       = google_secret_manager_secret.db_connection_string.name
}

output "db_connection_string_id" {
  description = "ID of the database connection string secret"
  value       = google_secret_manager_secret.db_connection_string.id
}

## API Biscuit private key.

output "biscuit_private_key" {
  sensitive   = true
  description = "Biscuit private key value"
  value       = google_secret_manager_secret.biscuit_private_key.name
}

output "biscuit_private_key_id" {
  description = "Biscuit private key ID"
  value       = google_secret_manager_secret.biscuit_private_key.id
}

## SMTP server.

output "smtp_connection_url" {
  sensitive   = true
  description = "Value of the SMTP connection URL secret"
  value       = google_secret_manager_secret.smtp_connection_url.name
}

output "smtp_connection_url_id" {
  description = "ID of the SMTP connection URL secret"
  value       = google_secret_manager_secret.smtp_connection_url.id
}

## Email sender address.

output "email_sender_address" {
  sensitive   = true
  description = "Value of the email sender address secret"
  value       = google_secret_manager_secret.email_sender_address.name
}

output "email_sender_address_id" {
  description = "ID of the email sender address secret"
  value       = google_secret_manager_secret.email_sender_address.id
}

## Master API key.

output "master_api_key" {
  sensitive   = true
  description = "Value of the master API key secret"
  value       = google_secret_manager_secret.master_api_key[0].name
}

output "master_api_key_id" {
  description = "ID of the master API key secret"
  value       = try(google_secret_manager_secret.master_api_key[0].id, null)
}
