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
    query = <<EOF
-- Count the number of transitions between each page on GOV.UK as collected by GA4.
-- Only transitions between pages that exist in the content store are included.
-- https://stackoverflow.com/a/70033601/937932

CREATE TEMP TABLE page_views AS (
  SELECT
    user_pseudo_id,
    (
      SELECT
        value.int_value
      FROM
        UNNEST(event_params)
      WHERE
        key = 'ga_session_id'
    ) AS ga_session_id,
    (
      SELECT
        REGEXP_REPLACE(value.string_value, r"[?#].*", "")
      FROM
        UNNEST(event_params)
      WHERE
        key = 'page_referrer'
    ) AS from_url,
    (
      SELECT
        REGEXP_REPLACE(value.string_value, r"[?#].*", "")
      FROM
        UNNEST(event_params)
      WHERE
        key = 'page_location'
    ) AS to_url,
  FROM `ga4-analytics-352613.analytics_330577055.events_*`
  WHERE
    event_name = 'page_view'
    AND _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_ADD(DATE(@run_date), INTERVAL - 8 DAY))
    AND _TABLE_SUFFIX <= FORMAT_DATE('%Y%m%d', DATE_ADD(DATE(@run_date), INTERVAL - 2 DAY))
);

EXPORT DATA OPTIONS(
  uri='gs://${var.project_id}-data-processed/ga4/page_to_page_transitions_*.csv.gz',
  format='CSV',
  compression='GZIP',
  overwrite=true,
  header=true
) AS

WITH

all_urls AS (
  SELECT url FROM `${var.project_id}.content.url`
  UNION ALL
  SELECT url FROM `${var.project_id}.content.parts`
)

SELECT
  COUNT(*) AS number_of_movements,
  COUNT(DISTINCT(user_pseudo_id)) AS number_of_user_pseudo_ids,
  COUNT(DISTINCT(CONCAT(user_pseudo_id, ga_session_id))) AS number_of_sessions,
  page_views.from_url,
  page_views.to_url
FROM page_views
INNER JOIN all_urls AS urls_from ON urls_from.url = page_views.from_url
INNER JOIN all_urls AS urls_to ON urls_to.url = page_views.to_url
GROUP BY
  page_views.from_url,
  page_views.to_url
HAVING
  number_of_movements > 5
  AND number_of_user_pseudo_ids > 5
  AND number_of_sessions > 5
ORDER BY
  number_of_movements DESC
EOF
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
      "serviceAccount:${google_service_account.gce_postgres.email}",
      "serviceAccount:${google_service_account.gce_neo4j.email}",
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
      "serviceAccount:cpto-content-metadata-sa@cpto-content-metadata.iam.gserviceaccount.com",
      "group:data-engineering@digital.cabinet-office.gov.uk",
      "group:data-analysis@digital.cabinet-office.gov.uk",
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
    "description": "A short identifier we send to Google Analytics for multi-valued fields. This means we avoid the truncated values we would get if we sent the path or slug of eg organisations."
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
    "type": "INTEGER",
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
    "type": "INTEGER",
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

resource "google_bigquery_table" "lines" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "lines"
  friendly_name = "Lines"
  description   = "Individual lines of content of pages"
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
    "type": "INTEGER",
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
    "name": "from_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "to_url",
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
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a taxon"
  },
  {
    "name": "homepage_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a taxon's home page on GOV.UK"
  },
  {
    "name": "level",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "Level of the taxon in the hierarchy, with level 1 as the top"
  }
]
EOF
}

resource "google_bigquery_table" "appointment_current" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_current"
  friendly_name = "Appointment current"
  description   = "Whether a role appointment is current"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role appointment on GOV.UK"
  },
  {
    "name": "current",
    "type": "BOOLEAN",
    "mode": "REQUIRED",
    "description": "Whether a role appointment is current"
  }
]
EOF
}

resource "google_bigquery_table" "appointment_ended_on" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_ended_on"
  friendly_name = "Appointment ended on"
  description   = "When an appointment to a role ended"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role appointment on GOV.UK"
  },
  {
    "name": "ended_on",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "When an appointment to a role ended"
  }
]
EOF
}

resource "google_bigquery_table" "appointment_person" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_person"
  friendly_name = "Appointment person"
  description   = "The person appointed to a role"
  schema        = <<EOF
[
  {
    "name": "appointment_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role appointment on GOV.UK"
  },
  {
    "name": "person_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a person on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "appointment_role" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_role"
  friendly_name = "Appointment role"
  description   = "The role that a person is appointed to"
  schema        = <<EOF
[
  {
    "name": "appointment_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role appointment on GOV.UK"
  },
  {
    "name": "role_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "appointment_started_on" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_started_on"
  friendly_name = "Appointment started on"
  description   = "When an appointment to a role started"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role appointment on GOV.UK"
  },
  {
    "name": "started_on",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "When an appointment to a role started"
  }
]
EOF
}

resource "google_bigquery_table" "appointment_url" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_url"
  friendly_name = "Appointment url"
  description   = "Unique URLs of role appointments on GOV.UK"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role appointment on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "role_url" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_url"
  friendly_name = "Unique URLs of roles on GOV.UK"
  description   = "Unique URLs of roles on the www.gov.uk domain"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a 'role' on the www.gov.uk domain"
  }
]
EOF
}

resource "google_bigquery_table" "role_content_id" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_content_id"
  friendly_name = "Role content ID"
  description   = "Content IDs of roles on GOV.UK"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
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

resource "google_bigquery_table" "role_description" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_description"
  friendly_name = "Role description"
  description   = "Description of a role on GOV.UK"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "description",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Description of a role"
  }
]
EOF
}

resource "google_bigquery_table" "role_document_type" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_document_type"
  friendly_name = "Role document type"
  description   = "Document type of a role on GOV.UK"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "document_type",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Document type of a role on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "role_attends_cabinet_type" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_attends_cabinet_type"
  friendly_name = "Role attends cabinet type"
  description   = "Whether the incumbent of a role attends cabinet"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "attends_cabinet_type",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Whether the incumbent of a role attends cabinet"
  }
]
EOF
}

resource "google_bigquery_table" "role_homepage_url" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_homepage_url"
  friendly_name = "Role hompage URL"
  description   = "URL of the homepage of a role"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "homepage_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of the homepage of a role"
  }
]
EOF
}

resource "google_bigquery_table" "role_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_content"
  friendly_name = "Role content"
  description   = "Content of 'role' pages"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a piece of static content on the www.gov.uk domain"
  },
  {
    "name": "govspeak",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The content of the page as govspeak"
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

resource "google_bigquery_table" "role_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_embedded_links"
  friendly_name = "Role embedded links"
  description   = "Text and URLs of hyperlinks from the text of 'role' pages"
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

resource "google_bigquery_table" "role_locale" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_locale"
  friendly_name = "Role locale"
  description   = "Locale of a role"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "locale",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Locale of a role on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "role_first_published_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_first_published_at"
  friendly_name = "Role first published at"
  description   = "When a role was first published"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role role on GOV.UK"
  },
  {
    "name": "first_published_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "When a role was first published"
  }
]
EOF
}

resource "google_bigquery_table" "role_phase" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_phase"
  friendly_name = "Role phase"
  description   = "Phase of a role"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "phase",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The service design phase of a role - https://www.gov.uk/service-manual/phases"
  }
]
EOF
}

resource "google_bigquery_table" "role_public_updated_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_public_updated_at"
  friendly_name = "Role publicly updated at"
  description   = "When a role was publicly updated"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role role on GOV.UK"
  },
  {
    "name": "public_updated_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "When a role was publicly updated"
  }
]
EOF
}

resource "google_bigquery_table" "role_publishing_app" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_publishing_app"
  friendly_name = "Role publishing app"
  description   = "Publishing app of a role"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "publishing_app",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Publishing app of a role on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "role_redirect" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_redirect"
  friendly_name = "Role redirect"
  description   = "Redirects of homepates of roles"
  schema        = <<EOF
[
  {
    "name": "from_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a homepage of a role on GOV.UK being redirected from"
  },
  {
    "name": "to_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a homepage of a role on GOV.UK being redirected to"
  }
]
EOF
}

resource "google_bigquery_table" "role_organisation" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_organisation"
  friendly_name = "Role organisation"
  description   = "Organisation to which a role belongs"
  schema        = <<EOF
[
  {
    "name": "organisation_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of an organisation on GOV.UK"
  },
  {
    "name": "role_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "role_payment_type" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_payment_type"
  friendly_name = "Role payment type"
  description   = "Payment type of roles"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "payment_type",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Payment type of a role on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "role_seniority" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_seniority"
  friendly_name = "Role seniority"
  description   = "Seniority of roles"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "seniority",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Seniority of a role on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "role_title" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_title"
  friendly_name = "Role title"
  description   = "Title of roles"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Title of a role on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "role_updated_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_updated_at"
  friendly_name = "Role updated at"
  description   = "When a role was updated"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role role on GOV.UK"
  },
  {
    "name": "updated_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "When a role was updated"
  }
]
EOF
}

resource "google_bigquery_table" "role_whip_organisation" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_whip_organisation"
  friendly_name = "Role whip organisation"
  description   = "Whip organisation of roles"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "whip_organisation",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Whip organisation of a role on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_table" "pagerank" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "pagerank"
  friendly_name = "Page rank"
  description   = "Page rank of pages on GOV.UK"
  schema        = <<EOF
[
  {
    "name": "url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL of a role on GOV.UK"
  },
  {
    "name": "pagerank",
    "type": "BIGNUMERIC",
    "mode": "REQUIRED",
    "description": "Page rank of a page on GOV.UK"
  }
]
EOF
}

resource "google_bigquery_dataset" "graph" {
  dataset_id    = "graph"
  friendly_name = "graph"
  description   = "GOV.UK content data as a graph"
  location      = "europe-west2"
}

data "google_iam_policy" "bigquery_dataset_graph" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_postgres.email}",
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
      "group:data-engineering@digital.cabinet-office.gov.uk",
      "group:data-analysis@digital.cabinet-office.gov.uk",
      "group:data-products@digital.cabinet-office.gov.uk"
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

resource "google_bigquery_dataset" "test" {
  dataset_id    = "test"
  friendly_name = "test"
  description   = "Test queries"
  location      = "europe-west2"
}

resource "google_bigquery_table" "tables_metadata" {
  dataset_id    = google_bigquery_dataset.test.dataset_id
  table_id      = "tables-metadata"
  friendly_name = "Tables metadata"
  description   = "Table modified date and row count, sorted ascending"
  view {
    use_legacy_sql = false
    query          = <<EOF
WITH tables AS (
  SELECT * FROM content.__TABLES__
  UNION ALL
  SELECT * FROM graph.__TABLES__
)
SELECT
  dataset_id,
  table_id,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified,
  row_count
FROM tables
ORDER BY
  last_modified,
  row_count
;
EOF
  }
}
