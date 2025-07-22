terraform {
  required_version = ">= 1.12.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

provider "google" {
  project = var.bootstrap_billing_project
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project
# Create the infrastructure project
resource "google_project" "infra_project" {
  name            = var.project_id
  project_id      = var.project_id
  billing_account = var.billing_account_id
  deletion_policy = "DELETE"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service
# Enable required APIs for web application infrastructure
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",  # Enables project and resource management via Google Cloud Resource Manager
    "compute.googleapis.com",               # Required for Compute Engine (VMs, MIGs, Load Balancers)
    "iam.googleapis.com",                   # Enables Identity and Access Management (IAM)
    "storage.googleapis.com",               # Required for Cloud Storage (e.g., Terraform state bucket)
    "certificatemanager.googleapis.com",    # Enables Google-managed SSL certificates
    "iap.googleapis.com",                   # Enables Identity-Aware Proxy (IAP) for secure access
    "cloudbuild.googleapis.com",            # Enables Cloud Build (needed for building Packer images via Cloud Build)
    "artifactregistry.googleapis.com",      # Optional: Enables Artifact Registry (if Docker images or artifacts are used)
    "secretmanager.googleapis.com",         # Enables Secret Manager API
  ])

  project = google_project.infra_project.project_id
  service = each.value

  disable_on_destroy           = false
  disable_dependent_services   = true
  depends_on = [google_project.infra_project]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
# Creates a Google Cloud service account used by the Terraform deployment pipeline
resource "google_service_account" "deployment_account" {
  account_id   = "deployment-account"
  display_name = "Deployment Service Account"
  project      = google_project.infra_project.project_id
  description  = "Service Account for Terraform deployment pipeline"

  depends_on = [google_project_service.required_apis]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address
# Global IP for our Load Balancer
resource "google_compute_global_address" "lb_ip" {
  name    = "si-lb-ip"
  project = google_project.infra_project.project_id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret.html
# Creates a Secret Manager secret for storing the GitHub Connect OAuth token
resource "google_secret_manager_secret" "gh_connect_oauth" {
  project   = google_project.infra_project.project_id
  secret_id = "gh-connect-oauth"

  replication {
    auto {}
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version
# Adds a version to the GitHub Connect OAuth secret, storing the actual OAuth token value.
resource "google_secret_manager_secret_version" "gh_connect_oauth_version" {
  secret      = google_secret_manager_secret.gh_connect_oauth.id
  secret_data = var.gh_oauth_token
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/storage_bucket
# Create a bucket for terraform state
resource "google_storage_bucket" "tf_state" {
  name                        = "${var.project_id}-tfstate"
  location                    = "EU"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  project                     = google_project.infra_project.project_id

  versioning {
    enabled = true
  }

  # Simple lifecycle rule for short project duration
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 3  # Keep only 3 versions
    }
  }

  depends_on = [google_project_service.required_apis]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam
# IAM permissions for the deployment account
resource "google_project_iam_member" "deployment_account_permissions" {
  for_each = toset([
    "roles/compute.instanceAdmin.v1",        # Create/manage VMs and MIG
    "roles/compute.loadBalancerAdmin",       # Create/manage HTTPS Load Balancer
    "roles/compute.networkAdmin",            # Create/manage VPC, subnets, firewall rules
    "roles/compute.securityAdmin",           # Manage firewall rules and IAP
    "roles/certificatemanager.editor",       # Create/manage SSL certificates
    "roles/iap.admin",                       # Configure Identity-Aware Proxy for SSH
    "roles/storage.admin",                   # For terraform state bucket access
    "roles/iam.serviceAccountUser",          # Use service accounts for compute instances
    "roles/monitoring.editor",               # Health checks and monitoring
    "roles/cloudbuild.builds.editor",        # Create/manage Cloud Build triggers and builds
    "roles/cloudbuild.serviceAgent",         # Required for Cloud Build service account access
    "roles/cloudbuild.connectionAdmin",      # Create/manage Cloud Build connections and repos
    "roles/resourcemanager.projectIamAdmin", # Allow IAM bindings project wide
    "roles/iam.serviceAccountAdmin",         # Allows creating, managing, and deleting service accounts in the project
    "roles/secretmanager.secretAccessor",    # Allows accessing secrets (needed to read GitHub PAT from Secret Manager)
    "roles/secretmanager.admin",             # Allows full management of secrets (needed to update/view IAM policy on secrets)
  ])

  project = google_project.infra_project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.deployment_account.email}"

  depends_on = [google_service_account.deployment_account]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam
# Deployment account: read/write access to state bucket
resource "google_storage_bucket_iam_binding" "tf_state_reader" {
  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.objectUser"
  members = [
    "serviceAccount:${google_service_account.deployment_account.email}",
  ]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_key
# Service Account Key for CI/CD
resource "google_service_account_key" "deployment_account_key" {
  service_account_id = google_service_account.deployment_account.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"

  count = var.create_service_account_key ? 1 : 0
}
