variable "project_id" {
  description = "The project ID to work in"
  type        = string
}

variable "region" {
  description = "The region to to deploy ressources in"
  type        = string
  default     = "europe-west1"
}

variable "name" {
  description = "The name of the Cloud SQL instance"
  type        = string
  default     = "hook0"
}

variable "db_name" {
  description = "The database name"
  type        = string
  default     = "hook0db"
}

variable "db_user" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "vpc_network" {
  description = "The name of the existing VPC where the Cloud SQL instance should be deployed"
  type        = string
}

variable "vpc_host_project_id" {
    description = "The project ID of the VPC host (for Shared VPC). Defaults to project_id if not specified."
    type        = string
    default     = null
}