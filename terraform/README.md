# 🚀 Terraform Deployment for Hook0 on GCP

Welcome to the Terraform documentation for deploying the open source webhook solution **hook0** to Google Cloud Platform (GCP). This project uses a modular Terraform approach to deploy and manage the various components of hook0 in a secure, scalable, and reproducible manner.

---

## 🎯 The Goal

The goal of this Terraform work was to deploy the open source webhook solution **hook0** into our GCP environment. Using the self-hosting architecture documentation and hook0's source code, we evaluated the required resources and built modular Terraform configurations for each component of the webhook system.

---

## 📦 The Hook0 Components

The main components of the hook0 webhook system architecture are:

- **API**:  
  A Rust web application that requires several dependencies provided via environment variables (e.g., database URL, SMTP connection URL, email sender address, app URL, biscuit private key, and master API key).  
- **PostgreSQL Database**:  
  A Cloud SQL instance running PostgreSQL, which stores event data and is used by both the API and the output worker.
- **SMTP Server**:  
  An SMTP server URL and a sender email address are needed for sending emails.
- **Frontend**:  
  A Vue.js application that provides a user interface for interacting with the webhook system. It may optionally include an `API_ENDPOINT` variable to point to the API.
- **Output Worker**:  
  A Rust application responsible for processing and dispatching webhook events. It shares the same PostgreSQL database as the API.
- **Webhook Target**(optional, only for testing purposes):  
  A lightweight HTTP server that serves as a target endpoint for testing webhook event delivery.

---

## 🗂️ Terraform Project Structure

Our Terraform code is organized to maximize reusability and clarity. Here’s a high-level overview of the directory structure:

```
terraform/
├── environments/ 
├    │ ├── dev/
├    │ ├── staging/ 
├    │ └── prod/ 
└── modules/google/
├    ├── cloud_run_api/     
├    ├── cloud_frontend/   
├    ├── cloud_run_output_worker/   
├    ├── cloud_sql/
├    ├── secrets/ 
├    ├── service_account/ 
├    └── cloud_run_webhook_target/
├──backend.tf 
├──provider.tf 
├──variables.tf 
├──README.md
```

---

## 🔍 Deep Dive into Each Module

### 💾 cloud_sql Module
- **Purpose:**  
  Creates a Cloud SQL instance for PostgreSQL.
- **Configuration Highlights:**  
  - PostgreSQL instance with auto-growing storage (starting at 20GB).
  - Deployed in a private VPC network to secure access from the internet.

### 🌐 cloud_run_frontend Module
- **Purpose:**  
  Deploys the hook0 frontend (a Vue.js app) as a Cloud Run service.
- **Configuration Highlights:**  
  - Deployed in a private VPC using a Serverless VPC Access Connector.
  - Ingress rule allowing all traffic for testing (can be tightened in production).

### ⚙️ cloud_run_api Module
- **Purpose:**  
  Deploys the hook0 API (Rust web application) as a Cloud Run service.
- **Configuration Highlights:**  
  - Requires environment variables for database URL, SMTP connection URL, sender email, app URL, biscuit private key, and master API key.
  - Also deploys supporting resources (Compute Router and NAT) to route traffic from Cloud Run to an external SMTP server.
  - **Note:** The master API key is used for testing and should be removed or replaced in production.

### 🛠️ cloud_run_output_worker Module
- **Purpose:**  
  Deploys the output worker as a Cloud Run service.
- **Configuration Highlights:**  
  - Since the worker is a background process and doesn’t listen on an HTTP port, a lightweight sidecar container is included to respond to Cloud Run’s health checks.
  - Environment variables include the database URL, worker name, and a flag to disable IP address checking.

### 📬 cloud_run_webhook_target Module
- **Purpose:**  
  Deploys a simple HTTP endpoint to test webhook delivery and event processing.

### 🔐 secrets Module
- **Purpose:**  
  Creates and manages sensitive values (database password, database user, connection string, biscuit private key, master API key, SMTP URL, sender email) in Secret Manager.
  
### 👤 service_account Module
- **Purpose:**  
  Creates a service account with the necessary IAM roles (e.g., `roles/cloudsql.client`, `roles/secretmanager.secretAccessor`) that Cloud Run services use to interact with Cloud SQL and Secret Manager.

---

## 🚀 Deployment to GCP

### **Manual Deployment**
1. **Pull the Terraform Code:**  
   Clone the repository containing your Terraform configuration.
2. **Configure Variables:**  
   In your chosen environment (e.g., `terraform/environments/dev`), define your variables in a `terraform.tfvars` file. This includes:
   - `db_password`, `db_user`
   - `vpc_network`
   - `repository_id`
   - `vpc_connector`
   - `biscuit_private_key`
   - `email_sender_address`
   - `smtp_connection_url`
   - `master_api_key`
3. **Initialize and Validate:**  
   Run:
   ```bash
   terraform init
   terraform fmt -check
   terraform validate
   ```
4. **Plan and Apply:**
    
    Run:
    ```bash 
    terraform plan -out plan.tfplan
    terraform apply "plan.tfplan"
    ```

### **Automatic Deployment**

- We set up a GitHub Actions workflow (see .github/workflows/terraform.yml) that triggers on changes to the terraform/ directory or via manual invocation.
- The workflow performs formatting, validation, planning, and (upon manual approval) applies the changes.
- Sensitive values for terraform.tfvars are stored in GitHub Secrets and injected during the workflow.

### **Local Testing**

- For local testing of Cloud Run services, you can use the gcloud run services proxy command:

  ```bash
  gcloud run services proxy <service-name> --port=<local-port> --region=<project-region>
  ```
- This allows you to test API calls with tools like Postman or through your browser with the UI.

---

## 📝 Final Notes

### **Security Considerations**:

- Secrets are stored securely in Secret Manager and injected into Cloud Run services as environment variables.
- The Terraform variable file (terraform.tfvars) is not committed to the repository; its contents are instead provided via GitHub Secrets.

### **Testing**:

- The webhook target module allows you to verify that the entire integration—API, output worker, and frontend—is working as expected.

### **Production Readiness**:

- Remember to remove the master API key before moving to production.
- Tighten ingress and egress rules as necessary once development is complete.

---

## 📚 References
- [Hook0 Documentation](https://documentation.hook0.com/docs/what-is-hook0)
- [GitHub Repository](https://github.com/hook0/hook0)
- [Terraform Google Module Docs](https://registry.terraform.io/modules/GoogleCloudPlatform)
