resource "google_project_service" "logging_googleapis_com" {
  project = "19513753240"
  service = "logging.googleapis.com"
}
# terraform import google_project_service.logging_googleapis_com 19513753240/logging.googleapis.com
