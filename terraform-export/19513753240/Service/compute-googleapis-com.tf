resource "google_project_service" "compute_googleapis_com" {
  project = "19513753240"
  service = "compute.googleapis.com"
}
# terraform import google_project_service.compute_googleapis_com 19513753240/compute.googleapis.com
