## Project
variable "project_id" {
  description = "The project ID to work in"
  type        = string
}

variable "region" {
  description = "The region to to deploy ressources in"
  type        = string
  default     = "europe-west1"
}

## Cloud SQL

variable "sql_name" {
  description = "The name of the Cloud SQL instance"
  type        = string
  default     = "hook0instance"
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

## Cloud Run API

variable "api_image" {
  description = "The image name to fetch from Artifact Registry"
  type        = string
  default     = "hook0-api:latest"
}

variable "api_service_name" {
  description = "The name of the Cloud Run service"
  type        = string
  default     = "hook0-api"
}

variable "api_container_port" {
  description = "The container port on which the API listens"
  type        = number
  default     = 8080
}

variable "api_invoker_members_iam" {
  description = "User or service account allowed to invoke the service"
  type        = list(string)
  default     = []
}

variable "master_api_key_readers" {
  description = "User or service account allowed to read the master API key"
  type        = list(string)
  default     = []
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

variable "biscuit_private_key" {
  description = "The biscuit private key"
  type        = string
  sensitive   = true
}

variable "master_api_key" {
  description = "The master API key"
  type        = string
  sensitive   = true
  default     = ""
}

## Cloud Run Frontend

variable "frontend_image" {
  description = "The image name to fetch from Artifact Registry"
  type        = string
  default     = "hook0-frontend:latest"
}

variable "frontend_service_name" {
  description = "The name of the Cloud Run service"
  type        = string
  default     = "hook0-frontend"
}

variable "frontend_container_port" {
  description = "The container port on which the API listens"
  type        = number
  default     = 80
}

## Cloud Run Output Worker

variable "output_worker_image" {
  description = "The image name to fetch from Artifact Registry"
  type        = string
  default     = "hook0-output-worker:latest"
}

variable "output_worker_pool_name" {
  description = "The name of the Cloud Run service"
  type        = string
  default     = "hook0-output-worker-wp"
}

variable "output_worker_container_port" {
  description = "The container port on which the output worker listens"
  type        = number
  default     = 8082
}
## VPC

variable "vpc_connector" {
  description = "The id of the serverless VPC Access connector"
  type        = string
}

variable "vpc_network" {
  description = "The name of the existing VPC where the Cloud SQL instance should be deployed"
  type        = string
}

## Artifact Registry

variable "repository_id" {
  description = "The id of the Artifact Registry repository"
  type        = string
}

variable "repository_project_id" {
  description = "The project id of the Artifact Registry repository"
  type        = string
}

## Housekeeping job / scheduler

variable "housekeeping_job_name" {
  description = "The name of the Cloud Run Job for housekeeping"
  type        = string
  default     = "hook0-housekeeping"
}

variable "housekeeping_cron" {
  description = "Cron schedule for housekeeping job (Cloud Scheduler)"
  type        = string
  default     = "0 3 * * *"
}

variable "housekeeping_time_zone" {
  description = "Time zone for the Cloud Scheduler job"
  type        = string
  default     = "UTC"
}

variable "housekeeping_delete" {
  description = "If true, housekeeping job will actually delete items"
  type        = bool
  default     = false
}

variable "housekeeping_full_reindex" {
  description = "If true, housekeeping will run full reindexes where applicable"
  type        = bool
  default     = false
}
