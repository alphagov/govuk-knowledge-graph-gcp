resource "google_iam_workload_identity_pool" "main" {
  provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
}

resource "google_iam_workload_identity_pool_provider" "main" {
  provider                           = google-beta
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-pool-provider"
  attribute_mapping                  = {
    # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri        = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Service Account"
  description = "Service account for applying Terraform from a GitHub Action"
}

resource "google_service_account_iam_member" "wif-sa" {
    service_account_id = google_service_account.terraform.name
    role               = "roles/iam.workloadIdentityUser"
    member             = "principalSet://iam.googleapis.com/projects/19513753240/locations/global/workloadIdentityPools/github-pool/attribute.repository/alphagov/govuk-knowledge-graph"
}

resource "google_project_iam_member" "terraform_iam_project" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}
