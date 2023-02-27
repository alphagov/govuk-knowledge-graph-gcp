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
  overwrite=true
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

resource "google_bigquery_dataset" "test" {
  dataset_id            = "test"
  friendly_name         = "test"
  description           = "Test queries"
  location              = "europe-west2"
  max_time_travel_hours = "48"
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
