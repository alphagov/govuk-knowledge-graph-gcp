environment                         = "development"
project_id                          = "govuk-knowledge-graph-dev"
project_number                      = "628722085506"
govgraph_domain                     = "govgraphdev.dev"
govgraphsearch_domain               = "govgraphsearchdev.dev"
govsearch_domain                    = "gov-search.integration.service.gov.uk"
application_title                   = "GovGraph Search (development)"
enable_auth                         = "true"
signon_url                          = "https://signon.integration.publishing.service.gov.uk"
oauth_auth_url                      = "https://signon.integration.publishing.service.gov.uk/oauth/authorize"
oauth_token_url                     = "https://signon.integration.publishing.service.gov.uk/oauth/access_token"
oauth_callback_url                  = "https://govgraphsearchdev.dev/auth/gds/callback"
gtm_auth                            = "PLACEHOLDER"
gtm_id                              = "PLACEHOLDER"
enable_redis_session_store_instance = true

# Google Groups and external service accounts that are to have roles given to
# them.
#
# Users shouldn't be given access directly, only via their membership of a
# Google Group.
#
# Service accounts that are internal to this Google Cloud Project shouldn't be
# included here. They should be given directly in the .tf files, because they
# should be the same in every environment.

project_owner_members = [
  "group:govgraph-developers@digital.cabinet-office.gov.uk",
]

iap_govgraphsearch_members = [
  "allUsers"
]

bigquery_job_user_members = [
]

# Bucket: {project_id}-data-processed
storage_data_processed_object_viewer_members = [
]

# BigQuery dataset: private
bigquery_private_data_viewer_members = [
]

# BigQuery dataset: public
bigquery_public_data_viewer_members = [
]

# BigQuery dataset: content
bigquery_content_data_viewer_members = [
]

# BigQuery dataset: publisher
bigquery_publisher_data_viewer_members = [
]

# BigQuery dataset: functions
bigquery_functions_data_viewer_members = [
]

# BigQuery dataset: graph
bigquery_graph_data_viewer_members = [
]

# BigQuery dataset: publishing-api
bigquery_publishing_api_data_viewer_members = [
]

# BigQuery dataset: smart_survey
bigquery_smart_survey_data_viewer_members = [
]

# BigQuery dataset: support-api
bigquery_support_api_data_viewer_members = [
]

# BigQuery dataset: search
bigquery_search_data_viewer_members = [
]

# BigQuery dataset: test
bigquery_test_data_viewer_members = [
]

# BigQuery dataset: whitehall
bigquery_whitehall_data_viewer_members = [
]

# BigQuery dataset: asset-manager
bigquery_asset_manager_data_viewer_members = [
]

# BigQuery dataset: zendesk
bigquery_zendesk_data_viewer_members = [
]
