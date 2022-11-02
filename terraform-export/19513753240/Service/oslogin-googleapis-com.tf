resource "google_project_service" "oslogin_googleapis_com" {
  project = "19513753240"
  service = "oslogin.googleapis.com"
}
# terraform import google_project_service.oslogin_googleapis_com 19513753240/oslogin.googleapis.com
