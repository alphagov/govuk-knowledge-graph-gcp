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
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_postgres.email}",
      "serviceAccount:${google_service_account.workflow_bank_holidays.email}",
      "serviceAccount:${google_service_account.bigquery_scheduled_queries_search.email}",
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
    members = [
      "projectReaders",
      "serviceAccount:${google_service_account.govgraphsearch.email}",
      "group:data-engineering@digital.cabinet-office.gov.uk",
      "group:data-analysis@digital.cabinet-office.gov.uk",
      "group:data-products@digital.cabinet-office.gov.uk",
      "serviceAccount:ner-bulk-inference@cpto-content-metadata.iam.gserviceaccount.com",
      "serviceAccount:wif-ner-new-content-inference@cpto-content-metadata.iam.gserviceaccount.com",
      "serviceAccount:${google_service_account.bigquery_scheduled_queries_search.email}",
    ]
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
  schema        = <<EOF
[
  {
    "mode": "REQUIRED",
    "name": "url",
    "type": "STRING",
    "description": "URL of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "document_type",
    "type": "STRING",
    "description": "The kind of thing that a page is about"
  },
  {
    "mode": "NULLABLE",
    "name": "phase",
    "type": "STRING",
    "description": "The service design phase of a page - https://www.gov.uk/service-manual/phases"
  },
  {
    "mode": "NULLABLE",
    "name": "content_id",
    "type": "STRING",
    "description": "The ID of the content item of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "analytics_identifier",
    "type": "STRING",
    "description": "A short identifier we send to Google Analytics for multi-valued fields. This means we avoid the truncated values we would get if we sent the path or slug of eg organisations."
  },
  {
    "mode": "NULLABLE",
    "name": "acronym",
    "type": "STRING",
    "description": "The official acronym of an organisation on GOV.UK"
  },
  {
    "mode": "NULLABLE",
    "name": "locale",
    "type": "STRING",
    "description": "The ISO 639-1 two-letter code of the language of an edition on GOV.UK"
  },
  {
    "mode": "NULLABLE",
    "name": "publishing_app",
    "type": "STRING",
    "description": "The application that published a content item on GOV.UK"
  },
  {
    "mode": "NULLABLE",
    "name": "updated_at",
    "type": "TIMESTAMP",
    "description": "When a page was last changed (however insignificantly)"
  },
  {
    "mode": "NULLABLE",
    "name": "public_updated_at",
    "type": "TIMESTAMP",
    "description": "When a page was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  },
  {
    "mode": "NULLABLE",
    "name": "first_published_at",
    "type": "TIMESTAMP",
    "description": "The date that a page was first published.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  },
  {
    "mode": "NULLABLE",
    "name": "withdrawn_at",
    "type": "TIMESTAMP",
    "description": "The date the page was withdrawn."
  },
  {
    "mode": "NULLABLE",
    "name": "withdrawn_explanation",
    "type": "STRING",
    "description": "The explanation for withdrawing a page"
  },
  {
    "mode": "NULLABLE",
    "name": "title",
    "type": "STRING",
    "description": "The title of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "description",
    "type": "STRING",
    "description": "Description of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "department_analytics_profile",
    "type": "STRING",
    "description": "Analytics identifier with which to record views"
  },
  {
    "mode": "NULLABLE",
    "name": "text",
    "type": "STRING",
    "description": "The content of the page as plain text extracted from the HTML"
  },
  {
    "mode": "NULLABLE",
    "name": "part_index",
    "type": "INTEGER",
    "description": "The order of the part among other parts in the same document, counting from 0"
  },
  {
    "mode": "NULLABLE",
    "name": "slug",
    "type": "STRING",
    "description": "What to add to the base_path to get the url"
  },
  {
    "mode": "NULLABLE",
    "name": "page_views",
    "type": "INTEGER",
    "description": "Number of page views from GA4 over 7 recent days"
  },
  {
    "mode": "NULLABLE",
    "name": "pagerank",
    "type": "BIGNUMERIC",
    "description": "Page rank of a page on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "part" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "part"
  friendly_name = "Part nodes"
  description   = "Part nodes, being part of multi-part pages"
  schema        = <<EOF
[
  {
    "mode": "REQUIRED",
    "name": "url",
    "type": "STRING",
    "description": "URL of a page node (not the same as the URL of the home"
  },
  {
    "mode": "NULLABLE",
    "name": "document_type",
    "type": "STRING",
    "description": "The kind of thing that a page is about"
  },
  {
    "mode": "NULLABLE",
    "name": "phase",
    "type": "STRING",
    "description": "The service design phase of a page - https://www.gov.uk/service-manual/phases"
  },
  {
    "mode": "NULLABLE",
    "name": "content_id",
    "type": "STRING",
    "description": "The ID of the content item of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "analytics_identifier",
    "type": "STRING",
    "description": "A short identifier we send to Google Analytics for multi-valued fields. This means we avoid the truncated values we would get if we sent the path or slug of eg organisations."
  },
  {
    "mode": "NULLABLE",
    "name": "acronym",
    "type": "STRING",
    "description": "The official acronym of an organisation on GOV.UK"
  },
  {
    "mode": "NULLABLE",
    "name": "locale",
    "type": "STRING",
    "description": "The ISO 639-1 two-letter code of the language of an edition on GOV.UK"
  },
  {
    "mode": "NULLABLE",
    "name": "publishing_app",
    "type": "STRING",
    "description": "The application that published a content item on GOV.UK"
  },
  {
    "mode": "NULLABLE",
    "name": "updated_at",
    "type": "TIMESTAMP",
    "description": "When a page was last changed (however insignificantly)"
  },
  {
    "mode": "NULLABLE",
    "name": "public_updated_at",
    "type": "TIMESTAMP",
    "description": "When a page was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  },
  {
    "mode": "NULLABLE",
    "name": "first_published_at",
    "type": "TIMESTAMP",
    "description": "The date that a page was first published.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  },
  {
    "mode": "NULLABLE",
    "name": "withdrawn_at",
    "type": "TIMESTAMP",
    "description": "The date the page was withdrawn."
  },
  {
    "mode": "NULLABLE",
    "name": "withdrawn_explanation",
    "type": "STRING",
    "description": "The explanation for withdrawing a page"
  },
  {
    "mode": "NULLABLE",
    "name": "part_title",
    "type": "STRING",
    "description": "The title of a part"
  },
  {
    "mode": "NULLABLE",
    "name": "description",
    "type": "STRING",
    "description": "Description of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "department_analytics_profile",
    "type": "STRING",
    "description": "Analytics identifier with which to record views"
  },
  {
    "mode": "NULLABLE",
    "name": "text",
    "type": "STRING",
    "description": "The content of the page as plain text extracted from the HTML"
  },
  {
    "mode": "NULLABLE",
    "name": "part_index",
    "type": "INTEGER",
    "description": "The order of the part among other parts in the same document, counting from 0"
  },
  {
    "mode": "NULLABLE",
    "name": "slug",
    "type": "STRING",
    "description": "What to add to the base_path of the part to get the url"
  },
  {
    "mode": "NULLABLE",
    "name": "page_views",
    "type": "INTEGER",
    "description": "Number of page views from GA4 over 7 recent days"
  },
  {
    "mode": "NULLABLE",
    "name": "pagerank",
    "type": "BIGNUMERIC",
    "description": "Page rank of a page on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "external_page" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "external_page"
  friendly_name = "External Page nodes"
  description   = "Unique URLs of pages not on the https://www.gov.uk domain"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a page that isn't on the https://www.gov.uk domain"
  }
]
EOF
}

resource "google_bigquery_table" "organisation" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "organisation"
  friendly_name = "Organisation nodes"
  description   = "Nodes that represent UK government organisations"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a UK government organisation"
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The name of an organisation"
  },
  {
    "name": "analytics_identifier",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "A short identifier we send to Google Analytics for multi-valued fields. This means we avoid the truncated values we would get if we sent the path or slug of eg organisations."
  },
  {
    "name": "content_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The ID of an organisation"
  },
  {
    "name": "phase",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The service design phase of an organisation - https://www.gov.uk/service-manual/phases"
  },
  {
    "name": "acronym",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The official acronym of an organisation on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "person" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "person"
  friendly_name = "Person nodes"
  description   = "Nodes that represent people in the UK government"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a person in the UK government"
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The name of a person"
  },
  {
    "name": "content_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The ID of a person"
  },
  {
    "name": "description",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Description of a person"
  }
]
EOF
}

resource "google_bigquery_table" "taxon" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "taxon"
  friendly_name = "Taxon nodes"
  description   = "Nodes that represent taxons on GOV.UK"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a taxon"
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The name of a taxon"
  },
  {
    "name": "description",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The description of a taxon"
  },
  {
    "name": "content_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The ID of a taxon"
  },
  {
    "name": "level",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": "Level of the taxon in the hierarchy, with level 1 as the top"
  }
]
EOF
}

resource "google_bigquery_table" "role" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "role"
  friendly_name = "Role nodes"
  description   = "Role nodes"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role"
  },
  {
    "name": "document_type",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The kind of role"
  },
  {
    "name": "phase",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The service design phase of a phase - https://www.gov.uk/service-manual/phases"
  },
  {
    "name": "content_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The ID of a role"
  },
  {
    "name": "locale",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The ISO 639-1 two-letter code of the language of a role"
  },
  {
    "name": "publishing_app",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The application that published a role"
  },
  {
    "name": "updated_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "When a role was last changed (however insignificantly)"
  },
  {
    "name": "public_updated_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "When a role was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  },
  {
    "name": "first_published_at",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "The date that a role was first published.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The title of a role"
  },
  {
    "name": "description",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Description of a role"
  },
  {
    "name": "text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the homepage of a role, as plain text extracted from the HTML"
  }
]
EOF
}

resource "google_bigquery_table" "hyperlinks_to" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "hyperlinks_to"
  friendly_name = "Hyperlinks To relationships"
  description   = "Which pages hyperlink to which other pages"
  schema        = <<EOF
[
  {
    "name": "count",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "Number of occurrences of a link with the same URL and link-text in the same document"
  },
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a page on GOV.UK"
  },
  {
    "name": "link_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL target of a hyperlink"
  },
  {
    "name": "link_text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Plain text that is displayed in place of the URL"
  }
]
EOF
}

resource "google_bigquery_table" "has_organisation" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_organisation"
  friendly_name = "Has Organisation relationship"
  description   = "Relationships between a page and an organisation"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a page"
  },
  {
    "name": "organisation_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a UK government organisation"
  }
]
EOF
}

resource "google_bigquery_table" "has_primary_publishing_organisation" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_primary_publishing_organisation"
  friendly_name = "Has Primary Publishing Organisation relationship"
  description   = "Relationships between a page and its primary publishing organisation"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a page"
  },
  {
    "name": "primary_publishing_organisation_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a UK government organisation"
  }
]
EOF
}

resource "google_bigquery_table" "has_child_organisation" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_child_organisation"
  friendly_name = "Has Child Organisation relationship"
  description   = "Relationships between an organisation and a subsidiary"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a UK government organisation"
  },
  {
    "name": "child_organisation_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a subsidiary organisation"
  }
]
EOF
}

resource "google_bigquery_table" "has_homepage" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_homepage"
  friendly_name = "Has Homepage relationships"
  description   = "Relationships between things and their homepage"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a thing on GOV.UK"
  },
  {
    "name": "homepage_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of the homepage of a thing"
  }
]
EOF
}

resource "google_bigquery_table" "has_role" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_role"
  friendly_name = "Has Role relationships"
  description   = "Relationships between people and roles"
  schema        = <<EOF
[
  {
    "name": "person_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a person"
  },
  {
    "name": "role_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role"
  },
  {
    "name": "started_on",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "When an appointment to a role started"
  },
  {
    "name": "ended_on",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "When an appointment to a role ended"
  }
]
EOF
}

resource "google_bigquery_table" "belongs_to" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "belongs_to"
  friendly_name = "Belongs To relationships"
  description   = "Relationships between role nodes and organisation nodes"
  schema        = <<EOF
[
  {
    "name": "organisation_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of an organisation"
  },
  {
    "name": "role_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role"
  }
]
EOF
}

resource "google_bigquery_table" "is_tagged_to" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "is_tagged_to"
  friendly_name = "Is Tagged To relationships"
  description   = "Relationships between page nodes and taxon nodes"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of page"
  },
  {
    "name": "taxon_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a taxon"
  }
]
EOF
}

resource "google_bigquery_table" "has_parent" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_parent"
  friendly_name = "Has Parent relationship"
  description   = "Relationships between a taxon and a more general taxon"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a taxon"
  },
  {
    "name": "parent_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a more general taxon"
  }
]
EOF
}

resource "google_bigquery_table" "taxon_ancestors" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "taxon_ancestors"
  friendly_name = "Taxon ancestors"
  description   = "One row per taxon per ancestor of that taxon"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a taxon"
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Title of a taxon"
  },
  {
    "name": "ancestor_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a more general taxon"
  },
  {
    "name": "ancestor_title",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Title of the more general taxon"
  }
]
EOF
}

resource "google_bigquery_table" "has_successor" {
  dataset_id    = google_bigquery_dataset.graph.dataset_id
  table_id      = "has_successor"
  friendly_name = "Has Successor relationship"
  description   = "Relationships between an organisation and its successor"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of an organisation"
  },
  {
    "name": "successor_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of its successor organisation"
  }
]
EOF
}
