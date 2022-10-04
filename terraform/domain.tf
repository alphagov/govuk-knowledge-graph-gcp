# https://cloud.google.com/load-balancing/docs/https/ext-https-lb-simple

# Bucket for a default HTML page that is open to the public
resource "google_storage_bucket" "website" {
  name                        = "${var.project_id}-website" # Must be globally unique
  force_destroy               = false                              # terraform won't delete the bucket unless it is empty
  location                    = var.location
  storage_class               = "STANDARD" # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
}

resource "google_storage_bucket_iam_policy" "website" {
  bucket      = google_storage_bucket.website.name
  policy_data = data.google_iam_policy.bucket_website.policy_data
}

data "google_iam_policy" "bucket_website" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "allUsers",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketOwner"
    members = [
      "projectEditor:govuk-knowledge-graph",
      "projectOwner:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketReader"
    members = [
      "projectViewer:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectOwner"
    members = [
      "projectEditor:govuk-knowledge-graph",
      "projectOwner:govuk-knowledge-graph",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectReader"
    members = [
      "projectViewer:govuk-knowledge-graph",
    ]
  }
}

resource "google_storage_bucket_object" "website_index" {
  name         = "index.html"
  content      = file("index.html")
  content_type = "text/html"
  bucket       = google_storage_bucket.website.name
}

resource "google_compute_backend_bucket" "website" {
  name        = "website"
  bucket_name = google_storage_bucket.website.name
}

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
  network = google_compute_network.cloudrun.id
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

# resource "google_compute_target_http_proxy" "govgraph" {
#   name             = "govgraph"
#   url_map          = google_compute_url_map.govgraph.id
# }

resource "google_compute_url_map" "govgraph" {
  name            = "govgraph"
  description     = "URL map for govgraph.dev"
  default_service = google_compute_backend_bucket.website.id

#   host_rule {
#     hosts        = ["*"]
#     path_matcher = "browser"
#   }

#   path_matcher {
#     name            = "browser"
#     default_service = google_compute_backend_bucket.website.id

#     path_rule {
#       paths   = ["/browser/*"]
#       service = google_compute_backend_service.govgraph.id
#     }
#   }
}

resource "google_compute_backend_service" "govgraph" {
  name          = "govgraph"
  port_name     = "neo4j"
  health_checks = [google_compute_health_check.govgraph.id]
  backend {
    balancing_mode               = "UTILIZATION"
    capacity_scaler              = 1
    group = google_compute_instance_group.govgraph.id
    max_connections              = 0
    max_connections_per_endpoint = 0
    max_connections_per_instance = 0
    max_rate                     = 0
    max_rate_per_endpoint        = 0
    max_rate_per_instance        = 0
    max_utilization              = 0
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
  # target      = google_compute_target_http_proxy.govgraph.id
  ip_protocol = "TCP"
  port_range  = 443
  # port_range  = 80
}
