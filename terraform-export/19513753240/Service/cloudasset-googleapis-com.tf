resource "google_project_service" "cloudasset_googleapis_com" {
  project = "19513753240"
  service = "cloudasset.googleapis.com"
}
# terraform import google_project_service.cloudasset_googleapis_com 19513753240/cloudasset.googleapis.com
