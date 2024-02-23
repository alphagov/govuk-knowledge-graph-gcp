# A service to use as a remote function in BigQuery
# Then create a place to put the app images
resource "google_cloud_run_v2_service" "parse_html" {
  name     = "parse-html"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    containers {
      image = "europe-west2-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}/parse-html:latest"
      resources {
        limits = {
          cpu    = "1000m" # If we put "1" or nothing, terraform reapplies it.
          memory = "2048Mi" # By experiment, necessary and sufficient.
        }
      }
    }
    # The function only handles one request at a time, which it enforces by
    # using a filesystem lock as a mutex. It might be worth telling GCP
    # explicitly, so that it might try to create more instances of the function.
    max_instance_request_concurrency = 1
  }
}

resource "google_bigquery_connection" "parse_html" {
  connection_id = "parse-html"
  description   = "Remote function parse_html"
  location      = var.region
  cloud_resource {}
}

data "google_iam_policy" "cloud_run_parse_html" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_bigquery_connection.parse_html.cloud_resource[0].service_account_id}",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "parse_html" {
  location    = var.region
  name        = google_cloud_run_v2_service.parse_html.name
  policy_data = data.google_iam_policy.cloud_run_parse_html.policy_data
}

# generate a random string suffix for a bigquery job to deploy the function
resource "random_string" "deploy_parse_html" {
  length  = 20
  special = false
}

## Run a bigquery job to deploy the remote function
resource "google_bigquery_job" "deploy_parse_html" {
  job_id   = "d_job_${random_string.deploy_parse_html.result}"
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

# Allow a workflow to attach the
# default ${project_number}-compute@developer.gserviceaccount.com  service account to a
# Cloud Run Service.
data "google_compute_default_service_account" "default" {
}

data "google_iam_policy" "compute_default_service_account" {
  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      google_service_account.artifact_registry_docker.member,
    ]
  }
}

resource "google_service_account_iam_policy" "compute_default_service_account" {
  service_account_id = data.google_compute_default_service_account.default.name
  policy_data        = data.google_iam_policy.compute_default_service_account.policy_data
}
