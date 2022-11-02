resource "google_project_service" "storage_googleapis_com" {
  project = "19513753240"
  service = "storage.googleapis.com"
}
# terraform import google_project_service.storage_googleapis_com 19513753240/storage.googleapis.com
