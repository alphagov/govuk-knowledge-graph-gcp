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

# Then create a DNS zone
resource "google_dns_managed_zone" "govgraphsearch" {
  name        = "govgraphsearch"
  description = "DNS zone for govgraphsearch domain"
  dns_name    = "${var.govgraphsearch_domain}."
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
  web_backend_service = module.govgraphsearch_lb.backend_services["govgraphsearch"].name
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

# https://cloud.google.com/blog/topics/developers-practitioners/new-terraform-module-serverless-load-balancing
# Creates:
module "govgraphsearch_lb" {
  source                          = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  project                         = var.project_id
  name                            = "govgraphsearch"
  ssl                             = true
  managed_ssl_certificate_domains = ["${var.govgraphsearch_domain}."]
  http_forward                    = true
  https_redirect                  = true
  backends = {
    govgraphsearch = {
      description             = null
      protocol                = "HTTP"
      port_name               = "http"
      enable_cdn              = false
      compression_mode        = null
      custom_request_headers  = null
      custom_response_headers = null
      security_policy         = null
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = [
        {
          group = google_compute_region_network_endpoint_group.govgraphsearch_eg.self_link
        }
      ]
      # Protect the app with IAP (Identity-Aware Proxy)
      iap_config = {
        enable               = true
        oauth2_client_id     = data.google_secret_manager_secret_version.iap_oauth_client_id.secret_data
        oauth2_client_secret = data.google_secret_manager_secret_version.iap_oauth_client_secret.secret_data
      }
    }
  }
}

# Direct DNS to the IP address of the frontend of the load balancer
resource "google_dns_record_set" "govgraphsearch" {
  name         = google_dns_managed_zone.govgraphsearch.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.govgraphsearch.name
  rrdatas      = [module.govgraphsearch_lb.external_ip]
}
