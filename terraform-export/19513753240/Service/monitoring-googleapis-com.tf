resource "google_project_service" "monitoring_googleapis_com" {
  project = "19513753240"
  service = "monitoring.googleapis.com"
}
# terraform import google_project_service.monitoring_googleapis_com 19513753240/monitoring.googleapis.com
