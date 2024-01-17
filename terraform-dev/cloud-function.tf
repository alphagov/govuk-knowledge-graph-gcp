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

# service-628722085506@gcf-admin-robot.iam.gserviceaccount.com

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

  # Force terraform to redeploy the function when the source code changes
  # https://github.com/hashicorp/terraform-provider-google/issues/1938#issuecomment-1229042663
  lifecycle {
    replace_triggered_by = [
      google_storage_bucket_object.govspeak_to_html
    ]
  }
}

resource "google_cloudfunctions2_function_iam_member" "cloud_functions_invoker" {
  project        = google_cloudfunctions2_function.govspeak_to_html.project
  location       = google_cloudfunctions2_function.govspeak_to_html.location
  cloud_function = google_cloudfunctions2_function.govspeak_to_html.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_bigquery_connection.govspeak_to_html.cloud_resource[0].service_account_id}"
}

resource "google_cloud_run_service_iam_member" "cloud_run_invoker" {
  project  = google_cloudfunctions2_function.govspeak_to_html.project
  location = google_cloudfunctions2_function.govspeak_to_html.location
  service  = google_cloudfunctions2_function.govspeak_to_html.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_bigquery_connection.govspeak_to_html.cloud_resource[0].service_account_id}"
}

resource "google_bigquery_connection" "govspeak_to_html" {
  connection_id = "govspeak-to-html"
  description   = "Remote function govspeak_to_html"
  location      = var.region
  cloud_resource {}
}

# generate a random string suffix for a bigquery job to deploy the function
resource "random_string" "random" {
  length  = 20
  special = false
}

## Run a bigquery job to deploy the remote function
resource "google_bigquery_job" "deploy_govspeak_to_html" {
  job_id   = "d_job_${random_string.random.result}"
  location = var.region

  query {
    priority = "INTERACTIVE"
    query = templatefile(
      "bigquery/govspeak-to-html.sql",
      {
        project_id = var.project_id
        region     = var.region
        uri        = google_cloudfunctions2_function.govspeak_to_html.service_config[0].uri
      }
    )
    create_disposition = "" # must be set to "" for scripts
    write_disposition  = "" # must be set to "" for scripts
  }

  lifecycle {
    replace_triggered_by = [
      google_storage_bucket_object.govspeak_to_html
    ]
  }
}
