# https://cloud.google.com/load-balancing/docs/https/ext-https-lb-simple

# Static external IP address for Neo4j.  Global addresses don't work, because
# they are only for load balancers, so it must be regional.
resource "google_compute_global_address" "govgraph" {
  name = "govgraph"
}

# Where does the static IP address go?
# rrdatas = [google_compute_address.neo4j.address]

resource "google_dns_managed_zone" "govgraph" {
  name        = "govgraph"
  description = "DNS zone for .dev domains"
  dns_name    = "govgraph.dev."
}

resource "google_dns_record_set" "govgraph" {
  name         = google_dns_managed_zone.govgraph.dns_name
  type         = "A"
  ttl          = 300 # time to live: seconds
  managed_zone = google_dns_managed_zone.govgraph.name
  # The IP address must be looked up
  # https://console.cloud.google.com/networking/addresses/list?project=govuk-knowledge-graph
  rrdatas = ["34.160.154.17"]
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "govgraph" {
  name = "govgraph"

  managed {
    domains = ["govgraph.dev."]
  }
}

resource "google_compute_instance_group" "govgraph" {
  name    = "govgraph"
  zone    = var.zone
  network = google_compute_network.default.id
  named_port {
    name = "neo4j"
    port = 7474
  }
}

resource "google_compute_firewall" "neo4j-health-check" {
  name          = "neo4j-health-check"
  direction     = "INGRESS"
  network       = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/networks/default"
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    ports    = ["7474"]
    protocol = "tcp"
  }
  target_service_accounts = [google_service_account.gce_neo4j.email]
}

resource "google_compute_target_https_proxy" "govgraph" {
  name             = "govgraph"
  url_map          = google_compute_url_map.govgraph.id
  ssl_certificates = [google_compute_managed_ssl_certificate.govgraph.id]
}

resource "google_compute_url_map" "govgraph" {
  name            = "govgraph"
  description     = "URL map for govgraph.dev"
  default_service = google_compute_backend_service.govgraph.id
}

resource "google_compute_backend_service" "govgraph" {
  name          = "govgraph"
  port_name     = "neo4j"
  health_checks = [google_compute_health_check.govgraph.id]
  backend {
    group = google_compute_instance_group.govgraph.id
  }
}

resource "google_compute_health_check" "govgraph" {
  name = "govgraph"
  http_health_check {
    port_name = "neo4j"
  }
}

resource "google_compute_global_forwarding_rule" "govgraph" {
  name        = "govgraph"
  ip_address  = google_compute_global_address.govgraph.id
  target      = google_compute_target_https_proxy.govgraph.id
  ip_protocol = "TCP"
  port_range  = 443
}
