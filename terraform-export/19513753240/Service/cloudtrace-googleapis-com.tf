resource "google_project_service" "cloudtrace_googleapis_com" {
  project = "19513753240"
  service = "cloudtrace.googleapis.com"
}
# terraform import google_project_service.cloudtrace_googleapis_com 19513753240/cloudtrace.googleapis.com
