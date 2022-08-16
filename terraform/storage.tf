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
