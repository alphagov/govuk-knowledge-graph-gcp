resource "google_project_service" "sourcerepo_googleapis_com" {
  project = "19513753240"
  service = "sourcerepo.googleapis.com"
}
# terraform import google_project_service.sourcerepo_googleapis_com 19513753240/sourcerepo.googleapis.com
