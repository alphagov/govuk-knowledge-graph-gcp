resource "google_service_account" "bigquery_page_transitions" {
  account_id   = "bigquery-page-transitions"
  display_name = "Service account for page transitions query"
  description  = "Service account for a scheduled BigQuery query of page-to-page transition counts"
}

resource "google_bigquery_data_transfer_config" "page_to_page_transitions" {
  display_name   = "Page-to-page transitions"
  data_source_id = "scheduled_query" # This is a magic word
  location       = var.region
  schedule       = "every day 03:00"
  params = {
    query = "${file("${var.page_to_page_transitions_sql_file}")}"
  }
  service_account_name = google_service_account.bigquery_page_transitions.email
}

resource "google_bigquery_dataset" "content" {
  dataset_id    = "content"
  friendly_name = "content"
  description   = "GOV.UK content data"
  location      = "europe-west2"
}

data "google_iam_policy" "bigquery_dataset_content_dataEditor" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      "serviceAccount:${google_service_account.gce_mongodb.email}",
    ]
  }
  binding {
    role = "roles/bigquery.dataOwner"
    members = [
      "projectOwners",
    ]
  }
  binding {
    members = [
      "projectReaders",
      "serviceAccount:${google_service_account.bigquery_page_transitions.email}",
    ]
    role = "roles/bigquery.dataViewer"
  }
}

resource "google_bigquery_dataset_iam_policy" "content" {
  dataset_id  = google_bigquery_dataset.content.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_content_dataEditor.policy_data
}

resource "google_bigquery_table" "url" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "url"
  friendly_name = "GOV.UK unique URLs"
  description   = "Unique URLs of static content on the www.gov.uk domain, not including parts of 'guide' and 'travel_advice' pages"

  schema = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of content on the www.gov.uk domain"
  }
]
EOF

}

resource "google_bigquery_table" "parts" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "parts"
  friendly_name = "URLs and titles of parts of guide and travel_advice documents"
  description   = "URLs, base_paths, slugs, indexes and titles of parts of guide and travel_advice documents"

  schema = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Complete URL of the part"
  },
  {
    "name": "base_path",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of the parent document of the part"
  },
  {
    "name": "slug",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "What to add to the base_path to get the url"
  },
  {
    "name": "part_index",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The order of the part among other parts in the same document, counting from 0"
  },
  {
    "name": "part_title",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The title of the part"
  }
]
EOF

}
