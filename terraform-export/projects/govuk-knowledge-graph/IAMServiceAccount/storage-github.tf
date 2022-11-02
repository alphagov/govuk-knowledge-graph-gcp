resource "google_service_account" "storage_github" {
  account_id   = "storage-github"
  description  = "Service account for using Cloud Storage from GitHub Actions"
  display_name = "Storage Service Account for GitHub"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.storage_github projects/govuk-knowledge-graph/serviceAccounts/storage-github@govuk-knowledge-graph.iam.gserviceaccount.com
