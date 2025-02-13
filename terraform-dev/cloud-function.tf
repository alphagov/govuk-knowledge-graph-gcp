resource "google_storage_bucket" "cloud_functions" {
  name                        = "${var.project_id}-cloud-functions" # Must be globally unique
  force_destroy               = false                               # terraform won't delete the bucket unless it is empty
  location                    = var.region
  storage_class               = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
}

resource "google_storage_bucket_iam_policy" "cloud_functions" {
  bucket      = google_storage_bucket.repository.name
  policy_data = data.google_iam_policy.bucket_repository.policy_data
}

data "google_iam_policy" "bucket_cloud_functions" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "service-${var.project_id}@gcf-admin-robot.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketOwner"
    members = [
      "projectEditor:${var.project_id}",
      "projectOwner:${var.project_id}",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketReader"
    members = [
      "projectViewer:${var.project_id}",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectOwner"
    members = [
      "projectEditor:${var.project_id}",
      "projectOwner:${var.project_id}",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectReader"
    members = [
      "projectViewer:${var.project_id}",
    ]
  }
}

data "archive_file" "govspeak_to_html" {
  type        = "zip"
  output_path = "/tmp/govspeak-to-html.zip"
  source_dir  = "../src/cloud-functions/govspeak-to-html"
}

resource "google_storage_bucket_object" "govspeak_to_html" {
  name   = "sourcecode.zip"
  bucket = google_storage_bucket.cloud_functions.name
  source = data.archive_file.govspeak_to_html.output_path # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "govspeak_to_html" {
  name        = "govspeak-to-html"
  location    = var.region
  description = "Render a GovSpeak string to HTML"

  build_config {
    runtime     = "ruby32"
    entry_point = "govspeak_to_html" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.cloud_functions.name
        object = google_storage_bucket_object.govspeak_to_html.name
      }
    }
    environment_variables = {
      # https://github.com/alphagov/government-frontend/blob/main/app.json
      GOVUK_APP_DOMAIN   = "www.gov.uk"
      GOVUK_WEBSITE_ROOT = "https://www.gov.uk"
    }
    docker_repository = "projects/${var.project_id}/locations/${var.region}/repositories/gcf-artifacts"
  }

  service_config {
    available_memory = "512Mi"
    # available_cpu = 1 # This function is CPU-bound and serial, so we need exactly one
    timeout_seconds    = 60
    max_instance_count = 100
    # max_instance_request_concurrency = 1
    environment_variables = {
      # https://github.com/alphagov/government-frontend/blob/main/app.json
      GOVUK_APP_DOMAIN   = "www.gov.uk"
      GOVUK_WEBSITE_ROOT = "https://www.gov.uk"
    }
  }

  # https://github.com/hashicorp/terraform-provider-google/issues/1938#issuecomment-1229042663
  lifecycle {
    replace_triggered_by = [
      google_storage_bucket_object.govspeak_to_html
    ]
  }
}

data "google_iam_policy" "cloud_function_govspeak_to_html" {
  binding {
    role = "roles/cloudfunctions.invoker"
    members = [
      "serviceAccount:${google_bigquery_connection.govspeak_to_html.cloud_resource[0].service_account_id}",
    ]
  }
}

resource "google_cloudfunctions2_function_iam_policy" "govspeak_to_html" {
  cloud_function = google_cloudfunctions2_function.govspeak_to_html.name
  policy_data    = data.google_iam_policy.cloud_function_govspeak_to_html.policy_data
}

data "google_iam_policy" "cloud_run_govspeak_to_html" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_bigquery_connection.govspeak_to_html.cloud_resource[0].service_account_id}",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "govspeak_to_html" {
  location    = var.region
  name        = google_cloudfunctions2_function.govspeak_to_html.name
  policy_data = data.google_iam_policy.cloud_run_govspeak_to_html.policy_data
}

resource "google_bigquery_connection" "govspeak_to_html" {
  connection_id = "govspeak-to-html"
  description   = "Remote function govspeak_to_html"
  location      = var.region
  cloud_resource {}
}

data "google_iam_policy" "bigquery_connection_govspeak_to_html" {
  binding {
    role = "roles/bigquery.connectionUser"
    members = [
      google_service_account.bigquery_scheduled_queries.member,
    ]
  }
}

resource "google_bigquery_connection_iam_policy" "govspeak_to_html" {
  connection_id = google_bigquery_connection.govspeak_to_html.connection_id
  policy_data   = data.google_iam_policy.bigquery_connection_govspeak_to_html.policy_data
}

# generate a random string suffix for a bigquery job to deploy the function
resource "random_string" "deploy_govspeak_to_html" {
  length  = 20
  special = false
}

## Run a bigquery job to deploy the remote function
resource "google_bigquery_job" "deploy_govspeak_to_html" {
  job_id   = "d_job_${random_string.deploy_govspeak_to_html.result}"
  location = var.region

  query {
    priority = "INTERACTIVE"
    query = templatefile(
      "bigquery/govspeak-to-html.sql",
      {
        project_id = var.project_id
        region     = var.region
        uri        = google_cloudfunctions2_function.govspeak_to_html.url
      }
    )
    create_disposition = "" # must be set to "" for scripts
    write_disposition  = "" # must be set to "" for scripts
  }
}
