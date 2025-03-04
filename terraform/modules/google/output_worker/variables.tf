variable "project_id" {
  description = "The project ID to work in"
  type        = string
}

variable "region" {
  description = "The region to to deploy ressources in"
  type        = string
  default     = "europe-west1"
}

variable "output_worker_service_name" {
  description = "The name of the Cloud Run service"
  type        = string
}

variable "output_worker_image" {
  description = "The fully qualified image URL to deploy from Artifact Registry"
  type        = string
}

variable "output_worker_container_port" {
  description = "The container port on which the output worker listens"
  type        = number
  default     = 8082
}

variable "database_url" {
  description = "The connection string for Cloud SQL Postgres instance"
  type        = string
}

variable "database_connection_name" {
  description = "The connection name for Cloud SQL Postgres instance"
  type        = string
}

variable "output_worker_service_account_email" {
  description = "The service account email to run the Cloud Run service"
  type        = string
}

variable "vpc_connector" {
  description = "The id of the serverless VPC Access connector"
  type        = string
}
