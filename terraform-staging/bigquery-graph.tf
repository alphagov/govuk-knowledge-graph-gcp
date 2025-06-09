# A dataset of tables to represent nodes and edges

resource "google_bigquery_dataset" "graph" {
  dataset_id            = "graph"
  friendly_name         = "graph"
  description           = "Deprecated: GOV.UK content data as a graph. Please use the 'private' and 'public' datsets instead."
  location              = var.region
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_graph" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      google_service_account.bigquery_scheduled_queries.member,
    ]
  }
  binding {
    role = "roles/bigquery.dataOwner"
    members = [
      "projectOwners",
    ]
  }
  binding {
    role = "roles/bigquery.dataViewer"
    members = concat(
      [
        "projectReaders",
      ],
      var.bigquery_graph_data_viewer_members,
    )
  }
}

resource "google_bigquery_dataset_iam_policy" "graph" {
  dataset_id  = google_bigquery_dataset.graph.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_graph.policy_data
}

resource "google_bigquery_table" "page" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "page"
  friendly_name = "Page nodes"
  description   = "Page nodes"
  schema        = file("schemas/graph/page.json")
}

resource "google_bigquery_table" "taxon" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "taxon"
  friendly_name = "Taxon nodes"
  description   = "Nodes that represent taxons on GOV.UK"
  schema        = file("schemas/graph/taxon.json")
}

resource "google_bigquery_table" "is_tagged_to" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "is_tagged_to"
  friendly_name = "Is Tagged To relationships"
  description   = "Relationships between page nodes and taxon nodes"
  schema        = file("schemas/graph/is-tagged-to.json")
}

# Refresh legacy tables from data in the 'public' dataset.
resource "google_bigquery_routine" "graph_is_tagged_to" {
  dataset_id      = google_bigquery_dataset.graph.dataset_id
  routine_id      = "is_tagged_to"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = file("bigquery/graph-is-tagged-to.sql")
}

resource "google_bigquery_routine" "graph_page" {
  dataset_id      = google_bigquery_dataset.graph.dataset_id
  routine_id      = "page"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = file("bigquery/graph-page.sql")
}

resource "google_bigquery_routine" "graph_taxon" {
  dataset_id      = google_bigquery_dataset.graph.dataset_id
  routine_id      = "taxon"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = file("bigquery/graph-taxon.sql")
}

resource "google_bigquery_data_transfer_config" "graph_batch" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Graph batch"
  location       = var.region
  schedule       = "every day 07:00"
  params = {
    query = file("bigquery/graph-batch.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries.email
}
