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

resource "google_storage_bucket_iam_member" "repository_objectAdmin" {
  bucket = google_storage_bucket.repository.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.storage_github.email}"
}

resource "google_storage_bucket_iam_member" "repository_objectViewer" {
  bucket = google_storage_bucket.repository.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.gce_mongodb.email}"
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

resource "google_storage_bucket_iam_member" "content_store_objectViewer" {
  bucket = google_storage_bucket.content_store.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.gce_mongodb.email}"
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

resource "google_storage_bucket_iam_member" "data_processed_objectAdmin" {
  bucket = google_storage_bucket.data_processed.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gce_mongodb.email}"
}
