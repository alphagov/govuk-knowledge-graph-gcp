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
      "serviceAccount:${google_service_account.storage_github.email}",
    ]
  }

  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_postgres.email}",
      "serviceAccount:${google_service_account.gce_neo4j.email}",
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

# Bucket for dataset extracted from MongoDB and Postgres for upload into Neo4j
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
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_postgres.email}",
      "serviceAccount:${google_service_account.gce_neo4j.email}",
      "serviceAccount:${google_service_account.bigquery_page_transitions.email}",
    ]
  }

  binding {
    role = "roles/storage.objectViewer"
    members = [
      "group:data-engineering@digital.cabinet-office.gov.uk",
      "group:data-products@digital.cabinet-office.gov.uk",
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

# Bucket for SSL certificates
resource "google_storage_bucket" "ssl_certificates" {
  name                        = "${var.project_id}-ssl-certificates" # Must be globally unique
  force_destroy               = false                                # terraform won't delete the bucket unless it is empty
  location                    = var.location
  storage_class               = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
}

resource "google_storage_bucket_iam_policy" "ssl_certificates" {
  bucket      = google_storage_bucket.ssl_certificates.name
  policy_data = data.google_iam_policy.bucket_ssl_certificates.policy_data
}

data "google_iam_policy" "bucket_ssl_certificates" {
  binding {
    role = "roles/storage.objectAdmin"
    members = [
      "serviceAccount:${google_service_account.gce_neo4j.email}",
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
