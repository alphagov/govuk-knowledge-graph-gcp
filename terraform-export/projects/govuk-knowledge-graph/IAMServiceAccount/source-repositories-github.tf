resource "google_service_account" "source_repositories_github" {
  account_id   = "source-repositories-github"
  description  = "Service account for pushing git repositories from GitHub Actions"
  display_name = "Source Repositories Service Account for GitHub"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.source_repositories_github projects/govuk-knowledge-graph/serviceAccounts/source-repositories-github@govuk-knowledge-graph.iam.gserviceaccount.com
