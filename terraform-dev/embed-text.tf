# A service to use as a remote function in BigQuery
# Then create a place to put the app images
resource "google_cloud_run_v2_service" "embed_text" {
  name     = "embed-text"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    containers {
      image = "europe-west2-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}/embed-text:latest"
      resources {
        limits = {
          cpu    = "1000m" # If we put "1" or nothing, terraform reapplies it.
          memory = "2048Mi"
        }
      }
    }
  }
}

resource "google_bigquery_connection" "embed_text" {
  connection_id = "embed-text"
  description   = "Remote function embed_text"
  location      = var.region
  cloud_resource {}
}

data "google_iam_policy" "cloud_run_embed_text" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_bigquery_connection.embed_text.cloud_resource[0].service_account_id}",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "embed_text" {
  location    = var.region
  name        = google_cloud_run_v2_service.embed_text.name
  policy_data = data.google_iam_policy.cloud_run_embed_text.policy_data
}

# generate a random string suffix for a bigquery job to deploy the function
resource "random_string" "deploy_embed_text" {
  length  = 20
  special = false
}

## Run a bigquery job to deploy the remote function
resource "google_bigquery_job" "deploy_embed_text" {
  job_id   = "d_job_${random_string.deploy_embed_text.result}"
  location = var.region

  query {
    priority = "INTERACTIVE"
    query = templatefile(
      "bigquery/embed-text.sql",
      {
        project_id = var.project_id
        region     = var.region
        uri        = google_cloud_run_v2_service.embed_text.uri
      }
    )
    create_disposition = "" # must be set to "" for scripts
    write_disposition  = "" # must be set to "" for scripts
  }

  lifecycle {
    replace_triggered_by = [
      google_cloud_run_v2_service.embed_text
    ]
  }
}
