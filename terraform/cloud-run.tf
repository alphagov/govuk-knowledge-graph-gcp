# A service to use as a remote function in BigQuery
# Then create a place to put the app images
resource "google_cloud_run_v2_service" "parse_html" {
  name     = "parse-html"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    containers {
      image = "europe-west2-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}/parse-html:latest"
    }
  }
}

data "google_iam_policy" "cloud_run_parse_html" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_bigquery_connection.govspeak_to_html.cloud_resource[0].service_account_id}",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "parse_html" {
  location    = var.region
  name        = google_cloud_run_v2_service.parse_html.name
  policy_data = data.google_iam_policy.cloud_run_parse_html.policy_data
}

## Run a bigquery job to deploy the remote function
resource "google_bigquery_job" "deploy_parse_html" {
  job_id   = "d_job_${random_string.random.result}"
  location = var.region

  query {
    priority = "INTERACTIVE"
    query = templatefile(
      "bigquery/parse-html.sql",
      {
        project_id = var.project_id
        region     = var.region
        uri        = google_cloud_run_v2_service.parse_html.uri
      }
    )
    create_disposition = "" # must be set to "" for scripts
    write_disposition  = "" # must be set to "" for scripts
  }

  lifecycle {
    replace_triggered_by = [
      google_cloud_run_v2_service.parse_html
    ]
  }
}
