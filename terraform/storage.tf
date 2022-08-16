# Bucket for a copy of the current state of the git repository
resource "google_storage_bucket" "repository" {
  name          = "${var.project_id}-repository" # Must be globally unique
  force_destroy = false                          # terraform won't delete the bucket unless it is empty
  location      = var.location
  storage_class = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
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
