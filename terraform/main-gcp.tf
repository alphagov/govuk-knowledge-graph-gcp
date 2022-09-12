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
  type    = string
  default = "development"
}

variable "project_id" {
  type    = string
  default = "govuk-knowledge-graph" # Change this
}

variable "project_number" {
  type    = string
  default = "19513753240" # Change this
}

variable "billing_account" {
  type    = string
  default = "015C7A-FAF970-B0D375" # Change this once you know it
}

variable "folder_id" {
  type    = string
  default = "278098142879" # Change this
}

variable "region" {
  type    = string
  default = "europe-west2" # Change this
}

variable "zone" {
  type    = string
  default = "europe-west2-a" # Change this
}

# Google Cloud Storage location https://cloud.google.com/storage/docs/locations
variable "location" {
  type    = string
  default = "EUROPE-WEST2"
}

variable "services" {
  type = list(any)
  default = [
    # List all the services you use here
    "storage.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com",
    "sourcerepo.googleapis.com",
    "workflows.googleapis.com",
  ]
}

# Set the Terraform provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#user_project_override
  user_project_override = true
}

# Set the Terraform provider
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

# Use a cheaper network tier
resource "google_compute_project_default_network_tier" "default" {
  network_tier = "STANDARD"
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
      "user:duncan.garmonsway@digital.cabinet-office.gov.uk",
      "user:max.froumentin@digital.cabinet-office.gov.uk",
    ]
  }

  binding {
    role = "roles/editor"
    members = [
      "serviceAccount:19513753240@cloudservices.gserviceaccount.com",
      "serviceAccount:govuk-knowledge-graph@appspot.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/appengine.serviceAgent"
    members = [
      "serviceAccount:service-19513753240@gcp-gae-service.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/artifactregistry.serviceAgent"
    members = [
      "serviceAccount:service-19513753240@gcp-sa-artifactregistry.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/cloudbuild.builds.builder"
    members = [
      "serviceAccount:19513753240@cloudbuild.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/cloudbuild.serviceAgent"
    members = [
      "serviceAccount:service-19513753240@gcp-sa-cloudbuild.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/compute.instanceAdmin.v1"
    members = [
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.workflow_mongodb.email}",
    ]
  }

  binding {
    role = "roles/compute.serviceAgent"
    members = [
      "serviceAccount:service-19513753240@compute-system.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/containerregistry.ServiceAgent"
    members = [
      "serviceAccount:service-19513753240@containerregistry.iam.gserviceaccount.com",
    ]
  }

  binding {
    members = [
      "serviceAccount:service-19513753240@gcp-sa-eventarc.iam.gserviceaccount.com",
    ]
    role = "roles/eventarc.serviceAgent"
  }

  binding {
    role = "roles/firestore.serviceAgent"
    members = [
      "serviceAccount:service-19513753240@gcp-sa-firestore.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountTokenCreator"
    members = [
      "serviceAccount:service-19513753240@gcp-sa-pubsub.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/networkmanagement.serviceAgent"
    members = [
      "serviceAccount:service-19513753240@gcp-sa-networkmanagement.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/pubsub.serviceAgent"
    members = [
      "serviceAccount:service-19513753240@gcp-sa-pubsub.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/workflows.invoker"
    members = [
      "serviceAccount:${google_service_account.eventarc.email}",
    ]
  }

  binding {
    role = "roles/workflows.serviceAgent"
    members = [
      "serviceAccount:service-19513753240@gcp-sa-workflows.iam.gserviceaccount.com",
    ]
  }
}
