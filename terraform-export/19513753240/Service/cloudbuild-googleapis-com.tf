resource "google_project_service" "cloudbuild_googleapis_com" {
  project = "19513753240"
  service = "cloudbuild.googleapis.com"
}
# terraform import google_project_service.cloudbuild_googleapis_com 19513753240/cloudbuild.googleapis.com
