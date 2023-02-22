# Resources that are specific to this environment

resource "google_compute_managed_ssl_certificate" "govsearch" {
  name        = "govsearch-cert"
  description = "The SSL certificate of the GGS service domain: gov-search.service.gov.uk"
  managed {
    domains = [
      var.govsearch_domain,
    ]
  }
}

resource "google_compute_target_https_proxy" "govgraphsearch" {
  name = "govgraphsearch-https-proxy"
  ssl_certificates = [
    google_compute_managed_ssl_certificate.govgraphsearch.self_link,
    google_compute_managed_ssl_certificate.govsearch.self_link,
  ]
  url_map = google_compute_url_map.govgraphsearch.self_link
}
