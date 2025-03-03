variable "project_id" {
  description = "The project ID to work in"
  type        = string
}

variable "db_name" {
  description = "The database name"
  type        = string
  default     = "hook0db"
}

variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}


variable "db_connection_string" {
  description = "The database connection string"
  type        = string
  sensitive   = true
}

variable "biscuit_private_key" {
  description = "The biscuit private key"
  type        = string
}

variable "smtp_connection_url" {
  description = "The SMTP connection URL"
  type        = string
  sensitive   = true
}

variable "email_sender_address" {
  description = "The email sender address"
  type        = string
}

variable "master_api_key" {
  description = "The master API key"
  type        = string
  sensitive   = true
}
