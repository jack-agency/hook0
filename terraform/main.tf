## Project
data "google_project" "main" {
  project_id = var.project_id
}

## Artifact Registry
data "google_artifact_registry_repository" "hook0_repository" {
  location      = var.region
  repository_id = var.repository_id
  project       = var.repository_project_id
}

data "google_artifact_registry_docker_image" "hook0_api" {
  location      = var.region
  repository_id = var.repository_id
  project       = var.repository_project_id
  image_name    = var.api_image
}

data "google_artifact_registry_docker_image" "hook0_frontend" {
  location      = var.region
  repository_id = var.repository_id
  project       = var.repository_project_id
  image_name    = var.frontend_image
}

data "google_artifact_registry_docker_image" "hook0_output_worker" {
  location      = var.region
  repository_id = var.repository_id
  project       = var.repository_project_id
  image_name    = var.output_worker_image
}

## Secrets

module "secrets" {
  source               = "./modules/google/secrets"
  project_id           = var.project_id
  db_name              = var.db_name
  db_user              = var.db_user
  db_password          = var.db_password
  smtp_connection_url  = var.smtp_connection_url
  biscuit_private_key  = var.biscuit_private_key
  email_sender_address = var.email_sender_address
  master_api_key       = var.master_api_key
  db_connection_string = module.cloud_sql.db_connection_string
}

## Cloud SQL

module "cloud_sql" {
  source      = "./modules/google/database"
  project_id  = var.project_id
  region      = var.region
  name        = var.sql_name
  db_name     = var.db_name
  db_user     = module.secrets.db_user_secret
  db_password = module.secrets.db_password_secret
  vpc_network = var.vpc_network
}

module "cloud_sql_iam" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = [var.project_id]

  mode = "additive"

  conditional_bindings = [
    {
      role        = "roles/cloudsql.client"
      title       = "cloud_sql_client"
      description = "Allow to connect to the instance \"${module.cloud_sql.instance_name}\""
      expression  = "resource.name == 'projects/${data.google_project.main.project_id}/instances/${module.cloud_sql.instance_name}' && resource.type == 'sqladmin.googleapis.com/Instance'"
      members     = ["serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"]
    },
    # {
    #   role        = "roles/cloudsql.instanceUser"
    #   title       = "cloud_sql_iam"
    #   description = "Allow to authenticate using IAM to the instance \"${module.cloud_sql.instance_name}\""
    #   expression  = "resource.name == 'projects/${data.google_project.main.project_id}/instances/${module.cloud_sql.instance_name}' && resource.type == 'sqladmin.googleapis.com/Instance'"
    #   members     = ["serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"]
    # }
  ]
}

## Cloud Run Frontend

module "frontend_cloud_run" {
  source                  = "./modules/google/frontend"
  project_id              = var.project_id
  region                  = var.region
  frontend_image          = data.google_artifact_registry_docker_image.hook0_frontend.self_link
  frontend_service_name   = var.frontend_service_name
  frontend_container_port = var.frontend_container_port
  api_service_name        = var.api_service_name
  vpc_connector           = var.vpc_connector
}

## Cloud Run API Service account

module "api_service_account" {
  source     = "./modules/google/service_account"
  project_id = var.project_id
}

resource "google_secret_manager_secret_iam_member" "sa_secret_accessor_db_password" {
  secret_id = module.secrets.db_password_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "sa_secret_accessor_db_user" {
  secret_id = module.secrets.db_user_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "sa_secret_accessor_biscuit_private_key" {
  secret_id = module.secrets.biscuit_private_key_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "sa_secret_accessor_smtp_connection_url" {
  secret_id = module.secrets.smtp_connection_url_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "sa_secret_accessor_email_sender_address" {
  secret_id = module.secrets.email_sender_address_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "sa_secret_accessor_master_api_key" {
  secret_id = module.secrets.master_api_key_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"
}

module "master_api_key_readers_secret_iam" {
  source = "terraform-google-modules/iam/google//modules/secret_manager_iam"

  count = length(var.master_api_key_readers) >= 1 ? 1 : 0

  project = var.project_id
  mode    = "additive"
  secrets = [module.secrets.master_api_key_id]

  bindings = {
    "roles/secretmanager.secretAccessor" = var.master_api_key_readers
  }
}

resource "google_secret_manager_secret_iam_member" "sa_secret_accessor_db_connection_string" {
  secret_id = module.secrets.db_connection_string_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"
}

## Cloud Run API

module "api_cloud_run" {
  source                    = "./modules/google/api"
  project_id                = var.project_id
  region                    = var.region
  api_image                 = data.google_artifact_registry_docker_image.hook0_api.self_link
  api_service_account_email = module.api_service_account.cloud_run_api_sa_email
  api_service_name          = var.api_service_name
  frontend_service_url      = "https://${var.frontend_service_name}-${data.google_project.main.number}.${var.region}.run.app" # The frontend service URL
  database_url              = module.secrets.db_connection_string
  database_connection_name  = module.cloud_sql.instance_connection_name
  vpc_connector             = var.vpc_connector
  vpc_network               = var.vpc_network
  biscuit_private_key       = module.secrets.biscuit_private_key
  smtp_connection_url       = module.secrets.smtp_connection_url
  email_sender_address      = module.secrets.email_sender_address
  master_api_key            = module.secrets.master_api_key
}

module "api_cloud_run_iam" {
  count = length(var.api_invoker_members_iam) >= 1 ? 1 : 0
  source = "terraform-google-modules/iam/google//modules/cloud_run_services_iam"

  cloud_run_services = [var.api_service_name]

  project  = var.project_id
  location = var.region
  mode     = "additive"

  bindings = {
    "roles/run.invoker" = var.api_invoker_members_iam
  }
}

## Cloud Run Output Worker

module "output_worker_cloud_run" {
  source                              = "./modules/google/output_worker"
  project_id                          = var.project_id
  region                              = var.region
  output_worker_image                 = data.google_artifact_registry_docker_image.hook0_output_worker.self_link
  output_worker_pool_name          = var.output_worker_pool_name
  database_url                        = module.secrets.db_connection_string
  database_connection_name            = module.cloud_sql.instance_connection_name
  vpc_connector                       = var.vpc_connector
  output_worker_service_account_email = module.api_service_account.cloud_run_api_sa_email
}