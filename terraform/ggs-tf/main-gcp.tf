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
  default = "europe-west2-b" # Change this
}

# Google Cloud Storage location https://cloud.google.com/storage/docs/locations
variable "location" {
  type    = string
  default = "EUROPE-WEST2"
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
