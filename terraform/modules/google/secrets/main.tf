## Secrets for Cloud SQL Database.

resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.db_name}-password"
  replication {
    auto {}
  }
  project = var.project_id
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

resource "google_secret_manager_secret" "db_user" {
  secret_id = "${var.db_name}-user"
  replication {
    auto {}
  }
  project = var.project_id
}

resource "google_secret_manager_secret_version" "db_user_version" {
  secret      = google_secret_manager_secret.db_user.id
  secret_data = var.db_user
}

resource "google_secret_manager_secret" "db_connection_string" {
  secret_id = "${var.db_name}-connection-string"
  replication {
    auto {}
  }
  project = var.project_id
}

resource "google_secret_manager_secret_version" "db_connection_string_version" {
  secret      = google_secret_manager_secret.db_connection_string.id
  secret_data = var.db_connection_string

  depends_on = [var.db_connection_string]
}

## Secrets for API Biscuit private key.

resource "google_secret_manager_secret" "biscuit_private_key" {
  secret_id = "hook0_api_biscuit_private_key"
  replication {
    auto {}
  }
  project = var.project_id
}

resource "google_secret_manager_secret_version" "biscuit_private_key_version" {
  secret      = google_secret_manager_secret.biscuit_private_key.id
  secret_data = var.biscuit_private_key
}

## Secret for the SMTP server

resource "google_secret_manager_secret" "smtp_connection_url" {
  secret_id = "hook0_smtp_connection_url"
  replication {
    auto {}
  }
  project = var.project_id
}

resource "google_secret_manager_secret_version" "smtp_connection_url_version" {
  secret      = google_secret_manager_secret.smtp_connection_url.id
  secret_data = var.smtp_connection_url
}

## Secret for the email sender address

resource "google_secret_manager_secret" "email_sender_address" {
  secret_id = "hook0_email_sender_address"
  replication {
    auto {}
  }
  project = var.project_id
}

resource "google_secret_manager_secret_version" "email_sender_address_version" {
  secret      = google_secret_manager_secret.email_sender_address.id
  secret_data = var.email_sender_address
}

## Secret for the master API key

resource "google_secret_manager_secret" "master_api_key" {
  count = length(var.master_api_key) > 0 ? 1 : 0

  secret_id = "hook0_master_api_key"
  replication {
    auto {}
  }
  project = var.project_id
}

resource "google_secret_manager_secret_version" "master_api_key_version" {
  count = length(var.master_api_key) > 0 ? 1 : 0

  secret      = google_secret_manager_secret.master_api_key[0].id
  secret_data = var.master_api_key
}
