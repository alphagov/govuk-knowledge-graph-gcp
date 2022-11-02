resource "google_project_service" "networkmanagement_googleapis_com" {
  project = "19513753240"
  service = "networkmanagement.googleapis.com"
}
# terraform import google_project_service.networkmanagement_googleapis_com 19513753240/networkmanagement.googleapis.com
