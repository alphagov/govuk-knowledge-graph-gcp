resource "google_project_service" "containerregistry_googleapis_com" {
  project = "19513753240"
  service = "containerregistry.googleapis.com"
}
# terraform import google_project_service.containerregistry_googleapis_com 19513753240/containerregistry.googleapis.com
