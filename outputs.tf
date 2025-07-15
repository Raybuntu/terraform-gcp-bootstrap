output "project_id" {
  description = "The project ID of the created project"
  value       = google_project.infra_project.project_id
}

output "deployment_service_account_email" {
  description = "Email address of the deployment service account"
  value       = google_service_account.deployment_account.email
}

output "terraform_state_bucket" {
  description = "Name of the Terraform state bucket"
  value       = google_storage_bucket.tf_state.name
}

output "service_account_key_json" {
  description = "Service account key JSON (if created)"
  value       = length(google_service_account_key.deployment_account_key) > 0 ? google_service_account_key.deployment_account_key[0].private_key : ""
  sensitive   = true
}

output "load_balancer_ip" {
  description = "IP address for the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "gh_connect_secret_id" {
  description = "GH connect oauth secret id"
  value       = google_secret_manager_secret.gh_connect_oauth.id
}

output "gh_connect_secret_name" {
  description = "GH connect oauth secret name"
  value       = google_secret_manager_secret.gh_connect_oauth.name
}
