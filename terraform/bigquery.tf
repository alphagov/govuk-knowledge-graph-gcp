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
    role = "roles/bigquery.dataViewer"
    members = [
      "projectReaders",
      "serviceAccount:${google_service_account.bigquery_page_transitions.email}",
      "group:data-engineering@digital.cabinet-office.gov.uk",
      "group:data-analysts@digital.cabinet-office.gov.uk",
      "group:data-products@digital.cabinet-office.gov.uk"
    ]
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
  description   = "Unique URLs of static content on the www.gov.uk domain, not including parts of 'guide' and 'travel_advice' pages, which are in the 'parts' table"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  }
]
EOF
}

resource "google_bigquery_table" "phase" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "phase"
  friendly_name = "Service design phases"
  description   = "The service design phase of content items - https://www.gov.uk/service-manual/phases"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "phase",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The service design phase of a content item - https://www.gov.uk/service-manual/phases"
  }
]
EOF
}

resource "google_bigquery_table" "content_id" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "content_id"
  friendly_name = "GOV.UK content ID"
  description   = "IDs of static content on the www.gov.uk domain"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "content_id",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The ID of a content item"
  }
]
EOF
}

resource "google_bigquery_table" "analytics_identifier" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "analytics_identifier"
  friendly_name = "Analytics identifier"
  description   = "A short identifier we send to Google Analytics for multi-valued fields. This means we avoid the truncated values we would get if we sent the path or slug of eg organisations."
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "analytics_identifier",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The ID of a piece of static content"
  }
]
EOF
}

resource "google_bigquery_table" "acronym" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "acronym"
  friendly_name = "Acronym"
  description   = "The official acronym of an organisation on GOV.UK"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "acronym",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The official acronym of an organisation on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "document_type" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "document_type"
  friendly_name = "Document type"
  description   = "The kind of thing that a content item on GOV.UK represents"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "document_type",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The kind of thing that a content item on GOV.UK represents"
  }
]
EOF
}

resource "google_bigquery_table" "locale" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "locale"
  friendly_name = "Locale"
  description   = "The ISO 639-1 two-letter code of the language of an edition on GOV.UK"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "locale",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The ISO 639-1 two-letter code of the language of an edition on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "publishing_app" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "publishing_app"
  friendly_name = "Publishing app"
  description   = "The application that published a content item on GOV.UK"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "publishing_app",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The application that published a content item on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "updated_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "updated_at"
  friendly_name = "Updated at date-time"
  description   = "When a content item was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "updated_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "When a content item was last changed (however insignificantly)"
  }
]
EOF
}

resource "google_bigquery_table" "public_updated_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "public_updated_at"
  friendly_name = "Public updated at date-time"
  description   = "When a content item was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "public_updated_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "When a content item was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  }
]
EOF
}

resource "google_bigquery_table" "first_published_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "first_published_at"
  friendly_name = "First published at date-time"
  description   = "The date the content was first published.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "first_published_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "The date the content was first published.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  }
]
EOF
}

resource "google_bigquery_table" "withdrawn_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "withdrawn_at"
  friendly_name = "Withdrawn at date-time"
  description   = "The date the content was withdrawn."
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "withdrawn_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "The date the content was withdrawn."
  }
]
EOF
}

resource "google_bigquery_table" "withdrawn_explanation" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "withdrawn_explanation"
  friendly_name = "Withdrawn explanation date-time"
  description   = "The explanation for withdrawing the content."
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "withdrawn_explanation",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The explanation for withdrawing the content."
  }
]
EOF
}

resource "google_bigquery_table" "title" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "title"
  friendly_name = "Title"
  description   = "Titles of static content on the www.gov.uk domain, not including parts of 'guide' and 'travel_advice' pages, which are in the 'parts' table."
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The title of a content item"
  }
]
EOF
}

resource "google_bigquery_table" "description" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "description"
  friendly_name = "Description"
  description   = "Descriptions of static content on the www.gov.uk domain."
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "description",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Description of a piece of static content"
  }
]
EOF
}

resource "google_bigquery_table" "department_analytics_profile" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "department_analytics_profile"
  friendly_name = "Department analytics profile"
  description   = "Analytics identifier with which to record views"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "department_analytics_profile",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Analytics identifier with which to record views"
  }
]
EOF
}

resource "google_bigquery_table" "transaction_start_link" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "transaction_start_link"
  friendly_name = "Transaction start link"
  description   = "Link that the start button will link the user to"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "link_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Link that the start button will link the user to"
  },
  {
    "name": "link_url_bare",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Link that the start button will link the user to, omitting parameters and anchors"
  }
]
EOF
}

resource "google_bigquery_table" "start_button_text" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "start_button_text"
  friendly_name = "Start-button text"
  description   = "Custom text to be displayed on the green button that leads you to another page"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "start_button_text",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Custom text to be displayed on the green button that leads you to another page"
  }
]
EOF
}

resource "google_bigquery_table" "expanded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "expanded_links"
  friendly_name = "Expanded links"
  description   = "Typed relationships between two URLs, from one to the other"
  schema        = <<EOF
[
  {
    "name": "link_type",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The type of the relationship between the URLs"
  },
  {
    "name": "from_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The origin URL"
  },
  {
    "name": "to_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The destination URL"
  }
]
EOF
}

resource "google_bigquery_table" "expanded_links_content_ids" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "expanded_links_content_ids"
  friendly_name = "Expanded links (content IDs)"
  description   = "Typed relationships between two content IDs, from one to the other"
  schema        = <<EOF
[
  {
    "name": "link_type",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The type of relationship between two content IDs, from one to the other"
  },
  {
    "name": "from_content_id",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The origin content ID"
  },
  {
    "name": "to_content_id",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The destination content ID"
  }
]
EOF
}

resource "google_bigquery_table" "parts" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "parts"
  friendly_name = "URLs and titles of parts of 'guide' and 'travel_advice' documents"
  description   = "URLs, base_paths, slugs, indexes and titles of parts of 'guide' and 'travel_advice' documents"
  schema        = <<EOF
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

resource "google_bigquery_table" "step_by_step_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "step_by_step_content"
  friendly_name = "Step-by-step content"
  description   = "Content of step-by-step pages"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "html",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as HTML"
  },
  {
    "name": "text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text extracted from the HTML"
  },
  {
    "name": "text_without_blank_lines",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text, omitting blank lines"
  }
]
EOF
}

resource "google_bigquery_table" "parts_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "parts_content"
  friendly_name = "Step-by-step content"
  description   = "Content of parts of 'guide' and 'travel_advice' documents"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "base_path",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of the parent document of the part"
  },
  {
    "name": "part_index",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The order of the part among other parts in the same document, counting from 0"
  },
  {
    "name": "html",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as HTML"
  },
  {
    "name": "text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text extracted from the HTML"
  },
  {
    "name": "text_without_blank_lines",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text, omitting blank lines"
  }
]
EOF
}

resource "google_bigquery_table" "transaction_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "transaction_content"
  friendly_name = "Transaction content"
  description   = "Content of 'transaction' documents"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "html",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as HTML"
  },
  {
    "name": "text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text extracted from the HTML"
  },
  {
    "name": "text_without_blank_lines",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text, omitting blank lines"
  }
]
EOF
}

resource "google_bigquery_table" "place_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "place_content"
  friendly_name = "Place content"
  description   = "Content of 'place' pages"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "html",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as HTML"
  },
  {
    "name": "text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text extracted from the HTML"
  },
  {
    "name": "text_without_blank_lines",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text, omitting blank lines"
  }
]
EOF
}

resource "google_bigquery_table" "body" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body"
  friendly_name = "Body content"
  description   = "Content of several types of pages, others are in tables with the suffix '_content'"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "html",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as HTML"
  },
  {
    "name": "text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text extracted from the HTML"
  },
  {
    "name": "text_without_blank_lines",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text, omitting blank lines"
  }
]
EOF
}

resource "google_bigquery_table" "body_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_content"
  friendly_name = "Body content content"
  description   = "Content of several types of pages, others are in tables with the suffix '_content'"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "html",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as HTML"
  },
  {
    "name": "text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text extracted from the HTML"
  },
  {
    "name": "text_without_blank_lines",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as plain text, omitting blank lines"
  }
]
EOF
}

resource "google_bigquery_table" "step_by_step_lines" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "step_by_step_lines"
  friendly_name = "Step-by-step lines"
  description   = "Individual lines of content of step-by-step pages"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "line_number",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "The order of the line of content in the document"
  },
  {
    "name": "line",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "A single line of plain-text content"
  }
]
EOF
}

resource "google_bigquery_table" "parts_lines" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "parts_lines"
  friendly_name = "Parts lines"
  description   = "Individual lines of content of parts of 'guide' and 'travel_advice' pages"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "base_path",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of the parent document of the part"
  },
  {
    "name": "part_index",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The order of the part among other parts in the same document, counting from 0"
  },
  {
    "name": "line_number",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "The order of the line of content in the document"
  },
  {
    "name": "line",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "A single line of plain-text content"
  }
]
EOF
}

resource "google_bigquery_table" "transaction_lines" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "transaction_lines"
  friendly_name = "Transaction lines"
  description   = "Individual lines of content of 'transaction' pages"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "line_number",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "The order of the line of content in the document"
  },
  {
    "name": "line",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "A single line of plain-text content"
  }
]
EOF
}

resource "google_bigquery_table" "place_lines" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "place_lines"
  friendly_name = "Place lines"
  description   = "Individual lines of content of 'place' pages"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "line_number",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "The order of the line of content in the document"
  },
  {
    "name": "line",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "A single line of plain-text content"
  }
]
EOF
}

resource "google_bigquery_table" "body_lines" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_lines"
  friendly_name = "Body lines"
  description   = "Individual lines of content of several types of pages, others are in tables with the suffix '_lines'"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "line_number",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "The order of the line of content in the document"
  },
  {
    "name": "line",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "A single line of plain-text content"
  }
]
EOF
}

resource "google_bigquery_table" "body_content_lines" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_content_lines"
  friendly_name = "Body content lines"
  description   = "Individual lines of content of several types of pages, others are in tables with the suffix '_lines'"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "line_number",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "The order of the line of content in the document"
  },
  {
    "name": "line",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "A single line of plain-text content"
  }
]
EOF
}

resource "google_bigquery_table" "step_by_step_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "step_by_step_embedded_links"
  friendly_name = "Step-by-step embedded links"
  description   = "Text and URLs of hyperlinks from the text of step-by-step pages"
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
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "link_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL target of a hyperlink"
  },
  {
    "name": "link_url_bare",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "URL target of a hyperlink, omitting parameters and anchors"
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

resource "google_bigquery_table" "parts_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "parts_embedded_links"
  friendly_name = "Parts embedded links"
  description   = "Text and URLs of hyperlinks from the text of parts of 'guide' and 'travel_advice' documents"
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
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "base_path",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of the parent document of the part"
  },
  {
    "name": "part_index",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The order of the part among other parts in the same document, counting from 0"
  },
  {
    "name": "link_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL target of a hyperlink"
  },
  {
    "name": "link_url_bare",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "URL target of a hyperlink, omitting parameters and anchors"
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

resource "google_bigquery_table" "transaction_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "transaction_embedded_links"
  friendly_name = "Transaction embedded links"
  description   = "Text and URLs of hyperlinks from the text of 'transaction' pages"
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
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "link_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL target of a hyperlink"
  },
  {
    "name": "link_url_bare",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "URL target of a hyperlink, omitting parameters and anchors"
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

resource "google_bigquery_table" "place_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "place_embedded_links"
  friendly_name = "Place embedded links"
  description   = "Text and URLs of hyperlinks from the text of 'place' pages"
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
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "link_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL target of a hyperlink"
  },
  {
    "name": "link_url_bare",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "URL target of a hyperlink, omitting parameters and anchors"
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

resource "google_bigquery_table" "body_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_embedded_links"
  friendly_name = "Body embedded links"
  description   = "Text and URLs of hyperlinks from the text of several types of pages, others are in tables with the suffix '_embedded_links'"
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
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "link_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL target of a hyperlink"
  },
  {
    "name": "link_url_bare",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "URL target of a hyperlink, omitting parameters and anchors"
  },
  {
    "name": "link_text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Plain text that is displayed in body of the URL"
  }
]
EOF
}

resource "google_bigquery_table" "body_content_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_content_embedded_links"
  friendly_name = "Body content embedded links"
  description   = "Text and URLs of hyperlinks from the text of several types of pages, others are in tables with the suffix '_embedded_links'"
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
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "link_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL target of a hyperlink"
  },
  {
    "name": "link_url_bare",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "URL target of a hyperlink, omitting parameters and anchors"
  },
  {
    "name": "link_text",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Plain text that is displayed in body of the URL"
  }
]
EOF
}

resource "google_bigquery_table" "url_override" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "url_override"
  friendly_name = "URL override"
  description   = "A kind of redirect on GOV.UK.  Another is 'redirects'"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "url_override",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL that overrides the other"
  }
]
EOF
}

resource "google_bigquery_table" "redirect" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "redirects"
  friendly_name = "Redirects"
  description   = "A kind of redirect on GOV.UK. Another is 'url_override'"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "url_override",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL that overrides the other"
  }
]
EOF
}

resource "google_bigquery_table" "taxon_levels" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "taxon_levels"
  friendly_name = "Taxon levels"
  description   = "The level of each taxon in the hierarchy, with level 1 as the top"
  schema        = <<EOF
[
  {
    "name": "level",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "Level of the taxon in the hierarchy, wiht level 1 as the top"
  },
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  }
]
EOF
}
