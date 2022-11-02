resource "google_service_account" "artifact_registry_docker" {
  account_id   = "artifact-registry-docker"
  description  = "Service account for pushing docker images"
  display_name = "Artifact Registry Service Account for Docker"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.artifact_registry_docker projects/govuk-knowledge-graph/serviceAccounts/artifact-registry-docker@govuk-knowledge-graph.iam.gserviceaccount.com
