resource "google_project_service" "artifactregistry_googleapis_com" {
  project = "19513753240"
  service = "artifactregistry.googleapis.com"
}
# terraform import google_project_service.artifactregistry_googleapis_com 19513753240/artifactregistry.googleapis.com
