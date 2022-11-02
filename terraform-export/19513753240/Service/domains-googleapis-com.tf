resource "google_project_service" "domains_googleapis_com" {
  project = "19513753240"
  service = "domains.googleapis.com"
}
# terraform import google_project_service.domains_googleapis_com 19513753240/domains.googleapis.com
