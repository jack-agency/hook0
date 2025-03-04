## Cloud SQL instance.

module "cloud_sql" {

  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "25.0.2"

  name             = var.name
  project_id       = var.project_id
  region           = var.region
  db_name          = var.db_name
  database_version = "POSTGRES_15"

  deletion_protection_enabled = true
  user_name                   = var.db_user
  user_password               = var.db_password

  tier            = "db-custom-2-8192" # 2 vCPUs, 8GB RAM
  disk_size       = 20                 # 20GB with auto-increase
  disk_autoresize = true
  disk_type       = "PD_SSD"

  deletion_protection = false

  # Private IP configuration
  ip_configuration = {
    private_network = "projects/${var.project_id}/global/networks/${var.vpc_network}"
    ipv4_enabled    = false
    require_ssl     = true
  }

  backup_configuration = {
    enabled    = true
    start_time = "23:00"
  }

  maintenance_window_day  = 7
  maintenance_window_hour = 3

  depends_on = [
    var.db_user,
    var.db_password
  ]
}
