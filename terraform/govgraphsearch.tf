# Create this first, on its own: The IAP OAuth consent screen (Identity-Aware
# Proxy)
resource "google_iap_brand" "project_brand" {
  # The support_email must be your own email address, or a Google Group that you
  # manage.
  support_email     = "duncan.garmonsway@digital.cabinet-office.gov.uk"
  application_title = var.application_title
}

# Then manually create OAUTH credentials:
# https://console.cloud.google.com/apis/credentials/oauthclient

# Add a redirect URI of the form
# https://iap.googleapis.com/v1/oauth/clientIds/CLIENT_ID:handleRedirect

# Then create the secrets in Secret Manager
# https://blog.gruntwork.io/a-comprehensive-guide-to-managing-secrets-in-your-terraform-code-1d586955ace1#bebe
resource "google_secret_manager_secret" "iap_oauth_client_id" {
  secret_id = "iap-oauth-client-id"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "iap_oauth_client_secret" {
  secret_id = "iap-oauth-client-secret"
  replication {
    automatic = true
  }
}

# Then manually paste the OAUTH credentials into the Secret Manager

# Then create a place to put the app images
resource "google_artifact_registry_repository" "cloud_run_source_deploy" {
  description   = "Cloud Run Source Deployments"
  format        = "DOCKER"
  location      = var.region
  repository_id = "cloud-run-source-deploy"
}

# Then push a docker image to that place.

# Then create DNS zones
resource "google_dns_managed_zone" "govgraphsearch" {
  name        = "govgraphsearch"
  description = "DNS zone for govgraphsearch domain"
  dns_name    = "${var.govgraphsearch_domain}."
}

resource "google_dns_managed_zone" "govsearch" {
  name        = "gov-search-zone"
  description = "The zone for the gov-search service domain"
  dns_name    = "${var.govsearch_domain}."
}

# Then manually buy a domain in Cloud Domains and link it to this zone.

# Then create everything else below.

# Retrieve the value of the secret
data "google_secret_manager_secret_version" "iap_oauth_client_id" {
  secret = "iap-oauth-client-id"
}

data "google_secret_manager_secret_version" "iap_oauth_client_secret" {
  secret = "iap-oauth-client-secret"
}

# Boilerplate
resource "google_compute_region_network_endpoint_group" "govgraphsearch_eg" {
  name   = "govgraphsearch-eg"
  region = var.region
  cloud_run {
    service = google_cloud_run_service.govgraphsearch.name
  }
}

# Connect to the same VPC where Neo4j is
resource "google_vpc_access_connector" "cloudrun_connector" {
  name = "cloudrun-connector"
  subnet {
    name = "cloudrun-subnet"
  }
}

# Allow access the app via IAP (Identity-Aware Proxy)
data "google_iam_policy" "govgraphsearch_iap" {
  binding {
    role    = "roles/iap.httpsResourceAccessor"
    members = var.govgraphsearch_iap_members
  }
}

resource "google_iap_web_backend_service_iam_policy" "govgraphsearch" {
  web_backend_service = google_compute_backend_service.govgraphsearch.name
  policy_data         = data.google_iam_policy.govgraphsearch_iap.policy_data
}

# Allow anyone who has already been through IAP to load the app
data "google_iam_policy" "govgraphsearch" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "govgraphsearch" {
  location    = var.region
  service     = google_cloud_run_service.govgraphsearch.name
  policy_data = data.google_iam_policy.govgraphsearch.policy_data
}

# Service account for the service
resource "google_service_account" "govgraphsearch" {
  account_id   = "govgraphsearch"
  display_name = "GovGraph Search"
  description  = "Service account for the GovGraph search Cloud Run app"
}

# The app itself
resource "google_cloud_run_service" "govgraphsearch" {
  name     = "govuk-knowledge-graph-search"
  location = var.region
  # https://github.com/hashicorp/terraform-provider-google/issues/9438#issuecomment-871946786
  autogenerate_revision_name = true
  metadata {
    annotations = {
      # The ingress setting can only be set when the cloudrun service already
      # exists.
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }
  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.cloudrun_connector.self_link
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
    spec {
      service_account_name = google_service_account.govgraphsearch.email
      containers {
        image = "europe-west2-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.cloud_run_source_deploy.repository_id}/govuk-knowledge-graph-search:latest"
        env {
          name  = "NEO4J_URL"
          value = "http://${google_compute_address.neo4j_internal.address}:7474/db/neo4j/tx"
        }
        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
      }
    }
  }
}

# We could use a lovely, convenient, official Google terraform module, which
# would create a lot of terraform for us behind the scenes, but unfortunately it
# forces downtime when adding/removing certificates for domains.
# https://cloud.google.com/blog/topics/developers-practitioners/new-terraform-module-serverless-load-balancing
# https://github.com/terraform-google-modules/terraform-google-lb-http/issues/241

resource "google_compute_backend_service" "govgraphsearch" {
  name      = "govgraphsearch-backend-govgraphsearch"
  port_name = "http"
  protocol  = "HTTP"
  backend {
    group = google_compute_region_network_endpoint_group.govgraphsearch_eg.self_link
  }
  iap {
    oauth2_client_id     = data.google_secret_manager_secret_version.iap_oauth_client_id.secret_data
    oauth2_client_secret = data.google_secret_manager_secret_version.iap_oauth_client_secret.secret_data
  }
}

resource "google_compute_global_address" "govgraphsearch" {
  name = "govgraphsearch-address"
}

resource "google_compute_global_forwarding_rule" "govgraphsearch_http" {
  name       = "govgraphsearch"
  port_range = "80"
  ip_address = google_compute_global_address.govgraphsearch.address
  target     = google_compute_target_http_proxy.govgraphsearch.self_link
}

resource "google_compute_global_forwarding_rule" "govgraphsearch_https" {
  name       = "govgraphsearch-https"
  port_range = "443"
  ip_address = google_compute_global_address.govgraphsearch.address
  target     = google_compute_target_https_proxy.govgraphsearch.self_link
}

resource "google_compute_managed_ssl_certificate" "govgraphsearch" {
  name = "govgraphsearch-cert"
  managed {
    domains = [
      var.govgraphsearch_domain,
    ]
  }
}

resource "google_compute_managed_ssl_certificate" "govsearch" {
  name        = "govsearch-cert"
  description = "The SSL certificate of the GGS service domain: gov-search.service.gov.uk"
  managed {
    domains = [
      var.govsearch_domain,
    ]
  }
}

resource "google_compute_target_http_proxy" "govgraphsearch" {
  name    = "govgraphsearch-http-proxy"
  url_map = google_compute_url_map.govgraphsearch_https_redirect.self_link
}

resource "google_compute_target_https_proxy" "govgraphsearch" {
  name = "govgraphsearch-https-proxy"
  ssl_certificates = [
    google_compute_managed_ssl_certificate.govgraphsearch.self_link,
    google_compute_managed_ssl_certificate.govsearch.self_link,
  ]
  url_map = google_compute_url_map.govgraphsearch.self_link
}

resource "google_compute_url_map" "govgraphsearch" {
  default_service = google_compute_backend_service.govgraphsearch.self_link
  name            = "govgraphsearch-url-map"
}

resource "google_compute_url_map" "govgraphsearch_https_redirect" {
  name = "govgraphsearch-https-redirect"
  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    https_redirect         = true
    strip_query            = false
  }
}

# Direct DNS to the IP address of the frontends of the load balancers
resource "google_dns_record_set" "govgraphsearch" {
  name         = google_dns_managed_zone.govgraphsearch.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.govgraphsearch.name
  rrdatas      = [google_compute_global_address.govgraphsearch.address]
}

resource "google_dns_record_set" "govsearch" {
  name         = google_dns_managed_zone.govsearch.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.govsearch.name
  rrdatas      = [google_compute_global_address.govgraphsearch.address]
}
