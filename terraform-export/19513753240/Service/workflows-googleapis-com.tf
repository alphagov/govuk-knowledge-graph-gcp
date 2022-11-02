resource "google_project_service" "workflows_googleapis_com" {
  project = "19513753240"
  service = "workflows.googleapis.com"
}
# terraform import google_project_service.workflows_googleapis_com 19513753240/workflows.googleapis.com
