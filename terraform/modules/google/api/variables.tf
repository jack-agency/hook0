variable "project_id" {
  description = "The project ID to work in"
  type        = string
}

variable "region" {
  description = "The region to to deploy ressources in"
  type        = string
  default     = "europe-west1"
}

variable "api_service_name" {
  description = "The name of the Cloud Run service"
  type        = string
}

variable "api_image" {
  description = "The fully qualified image URL to deploy from Artifact Registry"
  type        = string
}

variable "api_container_port" {
  description = "The container port on which the API listens"
  type        = number
  default     = 8081
}

variable "api_extra_env_vars" {
  description = "Optional additional environment variables as a list of objects with keys: name and value"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "frontend_service_url" {
  description = "The URL of the Cloud Run frontend service"
  type        = string
}

variable "database_url" {
  description = "The connection string for Cloud SQL Postgres instance"
  type        = string
  sensitive   = true
}

variable "api_service_account_email" {
  description = "The service account email to run the Cloud Run service"
  type        = string
}

variable "vpc_connector" {
  description = "The id of the serverless VPC Access connector"
  type        = string
}

variable "vpc_network" {
  description = "The id of the VPC network"
  type        = string
}

variable "biscuit_private_key" {
  description = "The biscuit private key"
  type        = string
  sensitive   = true
}

variable "email_sender_address" {
  description = "The email sender address"
  type        = string
}

variable "smtp_connection_url" {
  description = "The SMTP connection URL"
  type        = string
  sensitive   = true
}

variable "master_api_key" {
  description = "The master API key"
  type        = string
  sensitive   = true
  default = ""
}
