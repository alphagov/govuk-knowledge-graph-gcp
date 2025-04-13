# A function to forward an HTTP request to an API, and upload the response to a bucket.
resource "google_cloud_run_v2_service" "http_to_bucket" {
  name     = "http-to-bucket"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    containers {
      image = "europe-west2-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}/http-to-bucket:latest"
      resources {
        limits = {
          cpu    = "1000m"  # If we put "1" or nothing, terraform reapplies it.
          memory = "256Mi" # By experiment, necessary and sufficient.
        }
      }
    }
  }
}

data "google_iam_policy" "cloud_run_http_to_bucket" {
  binding {
    role = "roles/run.invoker"
    members = [
      google_service_account.workflow_smart_survey.member,
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "http_to_bucket" {
  location    = var.region
  name        = google_cloud_run_v2_service.http_to_bucket.name
  policy_data = data.google_iam_policy.cloud_run_http_to_bucket.policy_data
}
