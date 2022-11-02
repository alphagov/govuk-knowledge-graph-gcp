resource "google_project_service" "iamcredentials_googleapis_com" {
  project = "19513753240"
  service = "iamcredentials.googleapis.com"
}
# terraform import google_project_service.iamcredentials_googleapis_com 19513753240/iamcredentials.googleapis.com
