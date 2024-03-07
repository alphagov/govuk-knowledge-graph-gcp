# A dataset of tables to represent nodes and edges

resource "google_bigquery_dataset" "graph" {
  dataset_id            = "graph"
  friendly_name         = "graph"
  description           = "GOV.UK content data as a graph"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_graph" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      google_service_account.gce_mongodb.member,
      google_service_account.gce_publishing_api.member,
      google_service_account.bigquery_scheduled_queries_search.member,
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
        google_service_account.bigquery_scheduled_queries_search.member,
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

resource "google_bigquery_table" "part" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "part"
  friendly_name = "Part nodes"
  description   = "Part nodes, being part of multi-part pages"
  schema        = file("schemas/graph/part.json")
}

resource "google_bigquery_table" "external_page" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "external_page"
  friendly_name = "External Page nodes"
  description   = "Unique URLs of pages not on the https://www.gov.uk domain"
  schema        = file("schemas/graph/external-page.json")
}

resource "google_bigquery_table" "organisation" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "organisation"
  friendly_name = "Organisation nodes"
  description   = "Nodes that represent UK government organisations"
  schema        = file("schemas/graph/organisation.json")
}

resource "google_bigquery_table" "person" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "person"
  friendly_name = "Person nodes"
  description   = "Nodes that represent people in the UK government"
  schema        = file("schemas/graph/person.json")
}

resource "google_bigquery_table" "taxon" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "taxon"
  friendly_name = "Taxon nodes"
  description   = "Nodes that represent taxons on GOV.UK"
  schema        = file("schemas/graph/taxon.json")
}

resource "google_bigquery_table" "role" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "role"
  friendly_name = "Role nodes"
  description   = "Role nodes"
  schema        = file("schemas/graph/role.json")
}

resource "google_bigquery_table" "hyperlinks_to" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "hyperlinks_to"
  friendly_name = "Hyperlinks To relationships"
  description   = "Which pages hyperlink to which other pages"
  schema        = file("schemas/graph/hyperlinks-to.json")
}

resource "google_bigquery_table" "has_organisation" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_organisation"
  friendly_name = "Has Organisation relationship"
  description   = "Relationships between a page and an organisation"
  schema        = file("schemas/graph/has-organisation.json")
}

resource "google_bigquery_table" "has_primary_publishing_organisation" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_primary_publishing_organisation"
  friendly_name = "Has Primary Publishing Organisation relationship"
  description   = "Relationships between a page and its primary publishing organisation"
  schema        = file("schemas/graph/has-primary-publishing-organisation.json")
}

resource "google_bigquery_table" "has_child_organisation" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_child_organisation"
  friendly_name = "Has Child Organisation relationship"
  description   = "Relationships between an organisation and a subsidiary"
  schema        = file("schemas/graph/has-child-organisation.json")
}

resource "google_bigquery_table" "has_homepage" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_homepage"
  friendly_name = "Has Homepage relationships"
  description   = "Relationships between things and their homepage"
  schema        = file("schemas/graph/has-homepage.json")
}

resource "google_bigquery_table" "has_role" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_role"
  friendly_name = "Has Role relationships"
  description   = "Relationships between people and roles"
  schema        = file("schemas/graph/has-role.json")
}

resource "google_bigquery_table" "belongs_to" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "belongs_to"
  friendly_name = "Belongs To relationships"
  description   = "Relationships between role nodes and organisation nodes"
  schema        = file("schemas/graph/belongs-to.json")
}

resource "google_bigquery_table" "is_tagged_to" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "is_tagged_to"
  friendly_name = "Is Tagged To relationships"
  description   = "Relationships between page nodes and taxon nodes"
  schema        = file("schemas/graph/is-tagged-to.json")
}

resource "google_bigquery_table" "has_parent" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_parent"
  friendly_name = "Has Parent relationship"
  description   = "Relationships between a taxon and a more general taxon"
  schema        = file("schemas/graph/has-parent.json")
}

resource "google_bigquery_table" "taxon_ancestors" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "taxon_ancestors"
  friendly_name = "Taxon ancestors"
  description   = "One row per taxon per ancestor of that taxon"
  schema        = file("schemas/graph/taxon-ancestors.json")
}

resource "google_bigquery_table" "has_successor" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_successor"
  friendly_name = "Has Successor relationship"
  description   = "Relationships between an organisation and its successor"
  schema        = file("schemas/graph/has-successor.json")
}

resource "google_bigquery_table" "graph_phone_number" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "phone_number"
  friendly_name = "Phone number"
  description   = "Phone numbers from 'contact' documents or detected in page content by GovNER and libphonenumber"
  schema        = file("schemas/graph/phone-number.json")
}

# Refresh legacy tables from data in the 'public' dataset.
resource "google_bigquery_routine" "graph_page" {
  dataset_id      = google_bigquery_dataset.graph.dataset_id
  routine_id      = "page"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = file("bigquery/graph-page.sql")
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
