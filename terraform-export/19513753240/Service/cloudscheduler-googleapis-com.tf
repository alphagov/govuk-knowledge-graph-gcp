resource "google_project_service" "cloudscheduler_googleapis_com" {
  project = "19513753240"
  service = "cloudscheduler.googleapis.com"
}
# terraform import google_project_service.cloudscheduler_googleapis_com 19513753240/cloudscheduler.googleapis.com
