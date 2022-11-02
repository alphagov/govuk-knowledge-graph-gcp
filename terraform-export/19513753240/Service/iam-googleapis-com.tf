resource "google_project_service" "iam_googleapis_com" {
  project = "19513753240"
  service = "iam.googleapis.com"
}
# terraform import google_project_service.iam_googleapis_com 19513753240/iam.googleapis.com
