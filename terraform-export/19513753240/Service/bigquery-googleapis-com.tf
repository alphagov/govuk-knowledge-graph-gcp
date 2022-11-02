resource "google_project_service" "bigquery_googleapis_com" {
  project = "19513753240"
  service = "bigquery.googleapis.com"
}
# terraform import google_project_service.bigquery_googleapis_com 19513753240/bigquery.googleapis.com
