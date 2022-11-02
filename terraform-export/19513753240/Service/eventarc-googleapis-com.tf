resource "google_project_service" "eventarc_googleapis_com" {
  project = "19513753240"
  service = "eventarc.googleapis.com"
}
# terraform import google_project_service.eventarc_googleapis_com 19513753240/eventarc.googleapis.com
