resource "google_project_service" "dns_googleapis_com" {
  project = "19513753240"
  service = "dns.googleapis.com"
}
# terraform import google_project_service.dns_googleapis_com 19513753240/dns.googleapis.com
