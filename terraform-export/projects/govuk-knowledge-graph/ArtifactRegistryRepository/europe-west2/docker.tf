resource "google_artifact_registry_repository" "docker" {
  description   = "Docker repository"
  format        = "DOCKER"
  location      = "europe-west2"
  project       = "govuk-knowledge-graph"
  repository_id = "docker"
}
# terraform import google_artifact_registry_repository.docker projects/govuk-knowledge-graph/locations/europe-west2/repositories/docker
