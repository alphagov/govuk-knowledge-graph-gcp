# https://cloud.google.com/load-balancing/docs/https/ext-https-lb-simple

# Static external IP address for a Neo4j instance.  Global addresses don't work,
# because they are only for load balancers, so it must be regional.
resource "google_compute_address" "govgraph" {
  name = "govgraph"
  region = var.region
  address = "${var.govgraph_static_ip_address}"
}

resource "google_dns_managed_zone" "govgraph" {
  name        = "govgraph"
  description = "DNS zone for .dev domains"
  dns_name    = "${var.govgraph_domain}."
  dnssec_config {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 2048
      key_type   = "keySigning"
      kind       = "dns#dnsKeySpec"
    }
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 1024
      key_type   = "zoneSigning"
      kind       = "dns#dnsKeySpec"
    }
  }
}

resource "google_dns_record_set" "govgraph" {
  name         = google_dns_managed_zone.govgraph.dns_name
  type         = "A"
  ttl          = 300 # time to live: seconds
  managed_zone = google_dns_managed_zone.govgraph.name
  rrdatas = [google_compute_address.govgraph.address]
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "govgraph" {
  name = "govgraph"
  managed {
    domains = ["${var.govgraph_domain}"]
  }
}
