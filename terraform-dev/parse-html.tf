# A BigQuery remote function
data "archive_file" "parse_html" {
  type        = "zip"
  output_path = "/tmp/parse-html.zip"
  source_dir  = "../src/cloud-functions/parse-html"
}

resource "google_storage_bucket_object" "parse_html" {
  name   = "sourcecode.zip"
  bucket = google_storage_bucket.cloud_functions.name
  source = data.archive_file.parse_html.output_path # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "parse_html" {
  name        = "parse-html"
  location    = var.region
  description = "Extract HTML elements from GOV.UK content"

  build_config {
    runtime     = "ruby32"
    entry_point = "parse_html" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.cloud_functions.name
        object = google_storage_bucket_object.parse_html.name
      }
    }
    docker_repository = "projects/${var.project_id}/locations/${var.region}/repositories/gcf-artifacts"
  }

  service_config {
    available_memory = "512Mi"
    # available_cpu = 1 # This function is CPU-bound and serial, so we need exactly one
    timeout_seconds    = 60
    max_instance_count = 100
    # max_instance_request_concurrency = 1
  }
}

data "google_iam_policy" "cloud_function_parse_html" {
  binding {
    role = "roles/cloudfunctions.invoker"
    members = [
      "serviceAccount:${google_bigquery_connection.parse_html.cloud_resource[0].service_account_id}",
    ]
  }
}

resource "google_cloudfunctions2_function_iam_policy" "parse_html" {
  cloud_function = google_cloudfunctions2_function.parse_html.name
  policy_data    = data.google_iam_policy.cloud_function_parse_html.policy_data
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
  name        = google_cloudfunctions2_function.parse_html.name
  policy_data = data.google_iam_policy.cloud_run_parse_html.policy_data
}

resource "google_bigquery_connection" "parse_html" {
  connection_id = "parse-html"
  description   = "Remote function parse_html"
  location      = var.region
  cloud_resource {}
}

data "google_iam_policy" "bigquery_connection_parse_html" {
  binding {
    role = "roles/bigquery.connectionUser"
    members = [
      google_service_account.bigquery_scheduled_queries.member,
    ]
  }
}

resource "google_bigquery_connection_iam_policy" "parse_html" {
  connection_id = google_bigquery_connection.parse_html.connection_id
  policy_data   = data.google_iam_policy.bigquery_connection_parse_html.policy_data
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
        uri        = google_cloudfunctions2_function.parse_html.url
      }
    )
    create_disposition = "" # must be set to "" for scripts
    write_disposition  = "" # must be set to "" for scripts
  }
}
