resource "google_project_service" "serviceusage_googleapis_com" {
  project = "19513753240"
  service = "serviceusage.googleapis.com"
}
# terraform import google_project_service.serviceusage_googleapis_com 19513753240/serviceusage.googleapis.com
