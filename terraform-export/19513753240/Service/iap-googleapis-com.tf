resource "google_project_service" "iap_googleapis_com" {
  project = "19513753240"
  service = "iap.googleapis.com"
}
# terraform import google_project_service.iap_googleapis_com 19513753240/iap.googleapis.com
