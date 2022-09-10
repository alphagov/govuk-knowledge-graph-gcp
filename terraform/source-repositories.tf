# For GitHub Actions to push the repository to GCP

resource "google_sourcerepo_repository" "alphagov_govuk_knowledge_graph_gcp" {
  name = "alphagov/govuk-knowledge-graph-gcp"
}

resource "google_service_account" "source_repositories_github" {
  account_id   = "source-repositories-github"
  display_name = "Source Repositories Service Account for GitHub"
  description  = "Service account for pushing git repositories from GitHub Actions"
}

data "google_iam_policy" "source_repositories_alphagov_govuk_knowledge_graph_gcp" {
  binding {
    role = "roles/writer"
    members = [
      "serviceAccount:${google_service_account.source_repositories_github.email}",
    ]
  }
}

resource "google_sourcerepo_repository_iam_policy" "alphagov_govuk_knowledge_graph_gcp" {
  project     = google_sourcerepo_repository.alphagov_govuk_knowledge_graph_gcp.project
  repository  = google_sourcerepo_repository.alphagov_govuk_knowledge_graph_gcp.name
  policy_data = data.google_iam_policy.source_repositories_alphagov_govuk_knowledge_graph_gcp.policy_data
}
