# Bucket for a copy of the current state of the git repository
resource "google_storage_bucket" "repository" {
  name                        = "${var.project_id}-repository" # Must be globally unique
  force_destroy               = false                          # terraform won't delete the bucket unless it is empty
  location                    = var.location
  storage_class               = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
}

# Service account for GitHub to use the Cloud Storage
resource "google_service_account" "storage_github" {
  account_id   = "storage-github"
  display_name = "Storage Service Account for GitHub"
  description  = "Service account for using Cloud Storage from GitHub Actions"
}

data "google_iam_policy" "service_account_storage_github" {
  binding {
    role = "roles/iam.workloadIdentityUser"
    members = [
      "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-pool/attribute.repository/alphagov/govuk-knowledge-graph-gcp"
    ]
  }
}

resource "google_service_account_iam_policy" "storage_github" {
  service_account_id = google_service_account.storage_github.name
  policy_data        = data.google_iam_policy.service_account_storage_github.policy_data
}

resource "google_storage_bucket_iam_policy" "repository" {
  bucket      = google_storage_bucket.repository.name
  policy_data = data.google_iam_policy.bucket_repository.policy_data
}

data "google_iam_policy" "bucket_repository" {
  binding {
    role = "roles/storage.admin"
    members = [
      google_service_account.storage_github.member,
    ]
  }

  binding {
    role = "roles/storage.objectViewer"
    members = [
      google_service_account.gce_content.member,
      google_service_account.gce_mongodb.member,
      google_service_account.gce_postgres.member,
      google_service_account.gce_publisher.member,
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

# Bucket for dataset extracted from MongoDB and Postgres for upload into BigQuery
resource "google_storage_bucket" "data_processed" {
  name                        = "${var.project_id}-data-processed" # Must be globally unique
  force_destroy               = false                              # terraform won't delete the bucket unless it is empty
  location                    = var.location
  storage_class               = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
}

resource "google_storage_bucket_iam_policy" "data_processed" {
  bucket      = google_storage_bucket.data_processed.name
  policy_data = data.google_iam_policy.bucket_data_processed.policy_data
}

data "google_iam_policy" "bucket_data_processed" {
  binding {
    role = "roles/storage.objectAdmin"
    members = [
      google_service_account.gce_content.member,
      google_service_account.gce_mongodb.member,
      google_service_account.gce_postgres.member,
      google_service_account.gce_publisher.member,
      google_service_account.bigquery_page_transitions.member,
      google_service_account.workflow_bank_holidays.member,
    ]
  }

  binding {
    role = "roles/storage.objectViewer"
    members = concat([
      ],
      var.storage_data_processed_object_viewer_members,
    )
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

# Bucket for building Cloud Run apps
resource "google_storage_bucket" "cloudbuild" {
  name                        = "${var.project_id}_cloudbuild" # Must be globally unique
  force_destroy               = false                          # terraform won't delete the bucket unless it is empty
  location                    = var.location
  storage_class               = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
}

resource "google_storage_bucket_iam_policy" "cloudbuild" {
  bucket      = google_storage_bucket.cloudbuild.name
  policy_data = data.google_iam_policy.bucket_cloudbuild.policy_data
}

data "google_iam_policy" "bucket_cloudbuild" {
  binding {
    role = "roles/storage.objectAdmin"
    members = [
      google_service_account.govgraphsearch_deploy.member,
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

# Bucket for static copies of libaries, such as for BigQuery user-defined
# functions
resource "google_storage_bucket" "lib" {
  name                        = "${var.project_id}-lib" # Must be globally unique
  force_destroy               = false                   # terraform won't delete the bucket unless it is empty
  location                    = var.location
  storage_class               = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
}

resource "google_storage_bucket_iam_policy" "lib" {
  bucket      = google_storage_bucket.lib.name
  policy_data = data.google_iam_policy.bucket_lib.policy_data
}

data "google_iam_policy" "bucket_lib" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      google_service_account.gce_mongodb.member,
      # It isn't documented whether anyone needs any role for a BigQuery UDF to
      # be able to fetch a Javascript library from this bucket, but my guess is
      # that any user of the function, or any service account that runs a
      # scheduled query that uses the function, must have
      # roles/storage.objectViewer.
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

// Header files of CSV files, for concatenation.
// BigQuery exports a single, large table as many separate files, which then
// must be concatenated.  They are exported without headers, so that they can be
// concatenated without headers, and then they are concatenated onto these
// header files, which contain only the header row.
resource "google_storage_bucket_object" "content" {
  name   = "bigquery/content_header.csv.gz"
  source = "govuk-knowledge-graph-data-processed/bigquery/content_header.csv.gz"
  bucket = "${var.project_id}-data-processed"
}
resource "google_storage_bucket_object" "lines" {
  name   = "bigquery/lines_header.csv.gz"
  source = "govuk-knowledge-graph-data-processed/bigquery/lines_header.csv.gz"
  bucket = "${var.project_id}-data-processed"
}
resource "google_storage_bucket_object" "embedded_links" {
  name   = "bigquery/embedded_links_header.csv.gz"
  source = "govuk-knowledge-graph-data-processed/bigquery/embedded_links_header.csv.gz"
  bucket = "${var.project_id}-data-processed"
}
resource "google_storage_bucket_object" "page_to_page_transitions" {
  name   = "ga4/page_to_page_transitions_header.csv.gz"
  source = "govuk-knowledge-graph-data-processed/ga4/page_to_page_transitions_header.csv.gz"
  bucket = "${var.project_id}-data-processed"
}

# Javascript library for detecting phone numbers in plain text and standardising
# them.
resource "google_storage_bucket_object" "libphonenumber" {
  name   = "libphonenumber-max.js"
  source = "lib/libphonenumber-max.js"
  bucket = "${var.project_id}-lib"
}
