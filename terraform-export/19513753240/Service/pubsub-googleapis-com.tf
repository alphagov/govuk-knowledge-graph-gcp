resource "google_project_service" "pubsub_googleapis_com" {
  project = "19513753240"
  service = "pubsub.googleapis.com"
}
# terraform import google_project_service.pubsub_googleapis_com 19513753240/pubsub.googleapis.com
