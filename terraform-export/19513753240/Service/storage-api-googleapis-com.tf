resource "google_project_service" "storage_api_googleapis_com" {
  project = "19513753240"
  service = "storage-api.googleapis.com"
}
# terraform import google_project_service.storage_api_googleapis_com 19513753240/storage-api.googleapis.com
