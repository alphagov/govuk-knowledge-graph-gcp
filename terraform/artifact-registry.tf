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

data "google_iam_policy" "service_account_artifact_registry_docker" {
  binding {
    role = "roles/iam.workloadIdentityUser"
    members = [
      "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-pool/attribute.repository/alphagov/govuk-knowledge-graph-gcp"
    ]
  }
}

resource "google_service_account_iam_policy" "artifact_registry_docker" {
  service_account_id = google_service_account.artifact_registry_docker.name
  policy_data        = data.google_iam_policy.service_account_artifact_registry_docker.policy_data
}

resource "google_artifact_registry_repository_iam_policy" "docker" {
  project     = google_artifact_registry_repository.docker.project
  location    = google_artifact_registry_repository.docker.location
  repository  = google_artifact_registry_repository.docker.name
  policy_data = data.google_iam_policy.artifact_registry_docker.policy_data
}

data "google_iam_policy" "artifact_registry_docker" {
  binding {
    role = "roles/artifactregistry.reader"
    members = [
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_neo4j.email}",
    ]
  }

  binding {
    role = "roles/artifactregistry.writer"
    members = [
      "serviceAccount:${google_service_account.artifact_registry_docker.email}",
    ]
  }
}
