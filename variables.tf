variable "project_id" {
  description = "GCP project to be created"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID for the project"
  type        = string
}

variable "bootstrap_billing_project" {
  description = "Billing project used for API activation and resource creation"
  type        = string
}

variable "create_service_account_key" {
  description = "Control whether a service account key is created for CI/CD"
  type        = bool
  default     = false
}

variable "gh_oauth_token" {
  description = "OAUTH token for Cloud Build GH connections"
  type      = string
  sensitive = true
}
