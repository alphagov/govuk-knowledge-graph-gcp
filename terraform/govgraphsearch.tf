resource "google_artifact_registry_repository" "cloud_run_source_deploy" {
  description   = "Cloud Run Source Deployments"
  format        = "DOCKER"
  location      = "europe-west2"
  project       = "govuk-knowledge-graph"
  repository_id = "cloud-run-source-deploy"
}
# terraform import google_artifact_registry_repository.cloud_run_source_deploy projects/govuk-knowledge-graph/locations/europe-west2/repositories/cloud-run-source-deploy

resource "google_compute_target_https_proxy" "govgraphsearch_lb_target_proxy" {
  name             = "govgraphsearch-lb-target-proxy"
  project          = "govuk-knowledge-graph"
  quic_override    = "NONE"
  ssl_certificates = ["https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/sslCertificates/govgraphsearch-cert"]
  url_map          = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/urlMaps/govgraphsearch-lb"
}
# terraform import google_compute_target_https_proxy.govgraphsearch_lb_target_proxy projects/govuk-knowledge-graph/global/targetHttpsProxies/govgraphsearch-lb-target-proxy

resource "google_compute_global_forwarding_rule" "govgraphsearch_fc" {
  ip_address            = "34.160.154.17"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  name                  = "govgraphsearch-fc"
  port_range            = "443-443"
  project               = "govuk-knowledge-graph"
  target                = "https://www.googleapis.com/compute/beta/projects/govuk-knowledge-graph/global/targetHttpsProxies/govgraphsearch-lb-target-proxy"
}
# terraform import google_compute_global_forwarding_rule.govgraphsearch_fc projects/govuk-knowledge-graph/global/forwardingRules/govgraphsearch-fc

resource "google_dns_managed_zone" "govgraphsearcg" {
  dns_name      = "govgraphsearch.dev."
  force_destroy = false
  name          = "govgraphsearcg"
  project       = "govuk-knowledge-graph"
  visibility    = "public"
}
# terraform import google_dns_managed_zone.govgraphsearcg projects/govuk-knowledge-graph/managedZones/govgraphsearcg

resource "google_compute_global_address" "govgraphsearch_ip" {
  address      = "34.160.154.17"
  address_type = "EXTERNAL"
  description  = "External IP address for GovGraph Search"
  ip_version   = "IPV4"
  name         = "govgraphsearch-ip"
  project      = "govuk-knowledge-graph"
}
# terraform import google_compute_global_address.govgraphsearch_ip projects/govuk-knowledge-graph/global/addresses/govgraphsearch-ip

resource "google_compute_url_map" "govgraphsearch_lb" {
  default_service = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/backendServices/govgraphsearch-be"
  name            = "govgraphsearch-lb"
  project         = "govuk-knowledge-graph"
}
# terraform import google_compute_url_map.govgraphsearch_lb projects/govuk-knowledge-graph/global/urlMaps/govgraphsearch-lb

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "govgraphsearch_cert" {
  name = "govgraphsearch-cert"
  managed {
    domains = ["govgraphsearch.dev."]
  }
}
# terraform import google_compute_ssl_certificate.govgraphsearch_cert projects/govuk-knowledge-graph/global/sslCertificates/govgraphsearch-cert

# resource "google_compute_backend_service" "govgraphsearch_be" {
#   cdn_policy {
#     cache_key_policy {
#       include_host         = true
#       include_protocol     = true
#       include_query_string = true
#     }

#     cache_mode                   = "CACHE_ALL_STATIC"
#     client_ttl                   = 3600
#     default_ttl                  = 3600
#     max_ttl                      = 86400
#     signed_url_cache_max_age_sec = 0
#   }

#   connection_draining_timeout_sec = 0

#   iap {
#     oauth2_client_id = "19513753240-3ug13t89unh4hhcqnpunr0741ou6k2k2.apps.googleusercontent.com"
#   }

#   load_balancing_scheme = "EXTERNAL"
#   name                  = "govgraphsearch-be"
#   port_name             = "http"
#   project               = "govuk-knowledge-graph"
#   protocol              = "HTTPS"
#   session_affinity      = "NONE"
#   timeout_sec           = 30
# }
# terraform import google_compute_backend_service.govgraphsearch_be projects/govuk-knowledge-graph/global/backendServices/govgraphsearch-be

resource "google_cloud_run_service" "default" {
  autogenerate_revision_name = true
  location                   = "europe-west2"
  name                       = "govuk-knowledge-graph-search"
  project                    = "govuk-knowledge-graph"

  template {
    spec {
      container_concurrency = 80
      timeout_seconds       = 300

      containers {
        image   = "europe-west2-docker.pkg.dev/govuk-knowledge-graph/cloud-run-source-deploy/govuk-knowledge-graph-search:latest"

        env {
          name  = "NEO4J_URL"
          value = "http://10.8.0.4:7474/db/neo4j/tx"
        }
      }
    }
  }
}
