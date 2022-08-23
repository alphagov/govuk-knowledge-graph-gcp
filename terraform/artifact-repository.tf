# Service account for docker build to be run by GitHub Actions
# See also: ./workload-identity-fededocker build.tf

resource "google_artifact_registry_repository" "docker" {
  provider      = google-beta
  location      = lower(var.location)
  repository_id = "docker"
  description   = "Docker repository"
  format        = "DOCKER"
}

resource "google_service_account" "artifact_registry_docker" {
  account_id   = "artifact-registry-docker"
  display_name = "Artifact Registry Service Account for Docker"
  description  = "Service account for pushing docker images"
}

resource "google_artifact_registry_repository_iam_member" "docker_writer" {
  provider   = google-beta
  project    = google_artifact_registry_repository.docker.project
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.artifact_registry_docker.email}"
}

resource "google_artifact_registry_repository_iam_member" "docker_reader" {
  provider   = google-beta
  project    = google_artifact_registry_repository.docker.project
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${google_project.project.number}@compute-system.iam.gserviceaccount.com"
}
