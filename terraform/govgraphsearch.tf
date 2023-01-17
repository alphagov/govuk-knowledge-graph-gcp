resource "google_artifact_registry_repository" "cloud_run_source_deploy" {
  description   = "Cloud Run Source Deployments"
  format        = "DOCKER"
  location      = "europe-west2"
  repository_id = "cloud-run-source-deploy"
}

resource "google_compute_target_https_proxy" "govgraphsearch_lb_target_proxy" {
  name             = "govgraphsearch-lb-target-proxy"
  quic_override    = "NONE"
  ssl_certificates = [google_compute_managed_ssl_certificate.govgraphsearch_cert.id]
  url_map          = google_compute_url_map.govgraphsearch_lb.id
}

resource "google_compute_global_forwarding_rule" "govgraphsearch_fc" {
  ip_address            = google_compute_global_address.govgraphsearch_ip.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  name                  = "govgraphsearch-fc"
  port_range            = "443-443"
  target                = google_compute_target_https_proxy.govgraphsearch_lb_target_proxy.id
}

resource "google_dns_managed_zone" "govgraphsearcg" {
  dns_name      = "govgraphsearch.dev."
  force_destroy = false
  name          = "govgraphsearcg"
  visibility    = "public"
}

resource "google_compute_global_address" "govgraphsearch_ip" {
  address      = "${var.govgraphsearch_static_ip_address}"
  address_type = "EXTERNAL"
  description  = "External IP address for GovGraph Search"
  ip_version   = "IPV4"
  name         = "govgraphsearch-ip"
}

resource "google_compute_url_map" "govgraphsearch_lb" {
  default_service = "govgraphsearch-be"
  name            = "govgraphsearch-lb"
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "govgraphsearch_cert" {
  name = "govgraphsearch-cert"
  managed {
    domains = ["govgraphsearch.dev."]
  }
}
