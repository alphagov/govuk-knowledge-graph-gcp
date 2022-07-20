# Service account for terraform to be run by GitHub Actions
# See also: ./workload-identity-federation.tf

resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Service Account"
  description  = "Service account for applying Terraform from a GitHub Action"
}

resource "google_project_iam_member" "terraform_iam_project" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}
