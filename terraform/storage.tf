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
    role = "roles/storage.objectAdmin"
    members = [
      "serviceAccount:${google_service_account.storage_github.email}",
    ]
  }

  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_neo4j.email}",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketOwner"
    members = [
      "projectEditor:govuk-knowledge-graph",
      "projectOwner:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketReader"
    members = [
      "projectViewer:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectOwner"
    members = [
      "projectEditor:govuk-knowledge-graph",
      "projectOwner:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectReader"
    members = [
      "projectViewer:govuk-knowledge-graph",
    ]
  }
}

# Bucket for the Content Store MongoDB backup file
resource "google_storage_bucket" "content_store" {
  name                        = "${var.project_id}-content-store" # Must be globally unique
  force_destroy               = false                             # terraform won't delete the bucket unless it is empty
  location                    = var.location
  storage_class               = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_policy" "content_store" {
  bucket      = google_storage_bucket.content_store.name
  policy_data = data.google_iam_policy.bucket_content_store.policy_data
}

data "google_iam_policy" "bucket_content_store" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.gce_mongodb.email}",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketOwner"
    members = [
      "projectEditor:govuk-knowledge-graph",
      "projectOwner:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketReader"
    members = [
      "projectViewer:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectOwner"
    members = [
      "projectEditor:govuk-knowledge-graph",
      "projectOwner:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectReader"
    members = [
      "projectViewer:govuk-knowledge-graph",
    ]
  }
}

# Bucket for dataset extracted from MongoDB for upload into Neo4j
resource "google_storage_bucket" "data_processed" {
  name                        = "${var.project_id}-data-processed" # Must be globally unique
  force_destroy               = false                              # terraform won't delete the bucket unless it is empty
  location                    = var.location
  storage_class               = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
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
    ]
  }

  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.gce_neo4j.email}",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketOwner"
    members = [
      "projectEditor:govuk-knowledge-graph",
      "projectOwner:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketReader"
    members = [
      "projectViewer:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectOwner"
    members = [
      "projectEditor:govuk-knowledge-graph",
      "projectOwner:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectReader"
    members = [
      "projectViewer:govuk-knowledge-graph",
    ]
  }
}
