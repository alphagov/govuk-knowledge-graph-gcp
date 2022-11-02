resource "google_service_account" "bigquery_page_transitions" {
  account_id   = "bigquery-page-transitions"
  description  = "Service account for a scheduled BigQuery query of page-to-page transition counts"
  display_name = "Service account for page transitions query"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.bigquery_page_transitions projects/govuk-knowledge-graph/serviceAccounts/bigquery-page-transitions@govuk-knowledge-graph.iam.gserviceaccount.com
