resource "google_project_service" "bigquerystorage_googleapis_com" {
  project = "19513753240"
  service = "bigquerystorage.googleapis.com"
}
# terraform import google_project_service.bigquerystorage_googleapis_com 19513753240/bigquerystorage.googleapis.com
