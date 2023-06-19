# Adapted from https://medium.com/rockedscience/how-to-fully-automate-the-deployment-of-google-cloud-platform-projects-with-terraform-16c33f1fb31f

# ========================================================
# Create Google Cloud Projects from scratch with Terraform
# ========================================================
#
# This script is a workaround to fix an issue with the
# Google Cloud Platform API that prevents to fully
# automate the deployment of a project _from scratch_
# with Terraform, as described here:
# https://stackoverflow.com/questions/68308103/gcp-project-creation-via-api-doesnt-enable-service-usage-api
# It uses the `gcloud` CLI:
# https://cloud.google.com/sdk/gcloud
# in the pipeline. The `gcloud` CLI therefore needs to be
# installed and provided with sufficient credentials to
# consume the API.
# Full article:
# https://medium.com/rockedscience/how-to-fully-automate-the-deployment-of-google-cloud-platform-projects-with-terraform-16c33f1fb31f

# Set variables to reuse them across the resources
# and enforce consistency.
variable "environment" {
  type = string
}

variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

variable "billing_account" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

# Google Cloud Storage location https://cloud.google.com/storage/docs/locations
variable "location" {
  type = string
}

variable "govgraph_domain" {
  type = string
}

variable "govgraphsearch_domain" {
  type = string
}

variable "govsearch_domain" {
  type = string
}

variable "application_title" {
  type = string
}

variable "enable_auth" {
  type = string
}

variable "oauth_auth_url" {
  type = string
}

variable "oauth_token_url" {
  type = string
}

variable "oauth_callback_url" {
  type = string
}

variable "govgraphsearch_iap_members" {
  type = set(string)
}

variable "services" {
  type = list(any)
}

variable "postgres-startup-script" {
  type = string
}

variable "alerts_error_message_old_data" {
  type = string
}

variable "alerts_error_message_no_data" {
  type = string
}

variable "enable_redis_session_store_instance" {
  type = string
}

terraform {
  required_providers {
    google = {
      version = "4.46.0"
    }
    google-beta = {
      version = "4.46.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#user_project_override
  user_project_override = true
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_versions
  user_project_override = true
}

# Create the project
resource "google_project" "project" {
  billing_account = var.billing_account # Uncomment once known
  folder_id       = var.folder_id
  name            = var.project_id
  project_id      = var.project_id
  labels = {
    # The value can only contain lowercase letters, numeric characters,
    # underscores and dashes. The value can be at most 63 characters long.
    # International characters are allowed.
    programme = "cpto",
    team      = "data-products",
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Use `gcloud` to enable:
# - serviceusage.googleapis.com
# - cloudresourcemanager.googleapis.com
resource "null_resource" "enable_service_usage_api" {
  provisioner "local-exec" {
    command = "gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com --project ${var.project_id}"
  }

  depends_on = [google_project.project]
}

# Enable other services used in the project
resource "google_project_service" "services" {
  for_each = toset(var.services)

  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = false
  disable_on_destroy         = false

}

resource "google_compute_project_default_network_tier" "default" {
  # Premium for static global IP addresses.  Can be overridden by specific
  # instances that don't require those.
  network_tier = "PREMIUM"
}

resource "google_project_iam_policy" "project" {
  project     = var.project_id
  policy_data = data.google_iam_policy.project.policy_data
}

# All IAM members at the project level must be given here.
#
# If terraform is about to remove the permissions of a default service account,
# then that is probably because Google automatically created the account since
# this file was last updated. In that case, add the new permissions here and
# check the terraform plan again.
data "google_iam_policy" "project" {
  binding {
    role = "roles/owner"
    members = [
      "group:govsearch-developers@digital.cabinet-office.gov.uk",
    ]
  }

  binding {
    role = "roles/editor"
    members = [
      "serviceAccount:${var.project_number}@cloudservices.gserviceaccount.com",
      "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/appengine.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-gae-service.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/artifactregistry.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-artifactregistry.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/bigquery.jobUser"
    members = [
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_postgres.email}",
      "serviceAccount:${google_service_account.gce_neo4j.email}",
      "serviceAccount:${google_service_account.bigquery_page_transitions.email}",
      "serviceAccount:${google_service_account.bigquery_scheduled_queries_search.email}",
      "serviceAccount:${google_service_account.workflow_bank_holidays.email}",
      "serviceAccount:${google_service_account.govgraphsearch.email}",
      "group:data-engineering@digital.cabinet-office.gov.uk",
      "group:data-analysis@digital.cabinet-office.gov.uk",
      "group:data-products@digital.cabinet-office.gov.uk"
    ]
  }

  binding {
    role = "roles/bigquerydatatransfer.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com",
    ]
  }

  # For exporting everything as terraform
  binding {
    role = "roles/cloudasset.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-cloudasset.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/cloudasset.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-cloudasset.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/cloudbuild.builds.builder"
    members = [
      "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/cloudbuild.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/cloudscheduler.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/compute.instanceAdmin.v1"
    members = [
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_postgres.email}",
      "serviceAccount:${google_service_account.workflow_govuk_integration_database_backups.email}",
      "serviceAccount:${google_service_account.workflow_neo4j.email}",
    ]
  }

  binding {
    role = "roles/compute.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@compute-system.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/containerregistry.ServiceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@containerregistry.iam.gserviceaccount.com",
    ]
  }

  binding {
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-eventarc.iam.gserviceaccount.com",
    ]
    role = "roles/eventarc.serviceAgent"
  }

  binding {
    role = "roles/firestore.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-firestore.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountShortTermTokenMinter"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountTokenCreator"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/logging.logWriter"
    members = [
      "serviceAccount:${google_service_account.workflow_govuk_integration_database_backups.email}",
      "serviceAccount:${google_service_account.workflow_neo4j.email}",
      "serviceAccount:${google_service_account.workflow_bank_holidays.email}",
    ]
  }

  binding {
    role = "roles/networkmanagement.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-networkmanagement.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/pubsub.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/workflows.invoker"
    members = [
      "serviceAccount:${google_service_account.eventarc.email}",
      "serviceAccount:${google_service_account.scheduler_neo4j.email}",
      "serviceAccount:${google_service_account.scheduler_bank_holidays.email}",
      "serviceAccount:${google_service_account.scheduler_page_views.email}",
    ]
  }

  binding {
    role = "roles/run.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@serverless-robot-prod.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/vpcaccess.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-vpcaccess.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/workflows.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-workflows.iam.gserviceaccount.com",
    ]
  }

  # Add the necessary role and member for Redis service account
  binding {
    role = "roles/redis.serviceAgent"
    members = [
      "serviceAccount:service-${var.project_number}@cloud-redis.iam.gserviceaccount.com"
    ]
  }
}
