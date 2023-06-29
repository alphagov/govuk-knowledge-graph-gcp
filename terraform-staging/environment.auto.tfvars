environment                         = "staging"
project_id                          = "govuk-knowledge-graph-staging"
project_number                      = "957740527277"
govgraph_domain                     = "govgraphstaging.dev"
govgraphsearch_domain               = "govgraphsearchstaging.dev"
govsearch_domain                    = "gov-search.staging.service.gov.uk"
application_title                   = "GovGraph Search (staging)"
enable_auth                         = "false"
signon_url                          = "https://signon.publishing.service.gov.uk"
oauth_auth_url                      = "https://signon.publishing.service.gov.uk/oauth/authorize"
oauth_token_url                     = "https://signon.publishing.service.gov.uk/oauth/access_token"
oauth_callback_url                  = "https://govgraphsearch.dev/auth/gds/callback"
enable_redis_session_store_instance = false
gtm_auth                            = "PLACEHOLDER"
gtm_id                              = "PLACEHOLDER"
govgraphsearch_iap_members = [
  "group:data-products@digital.cabinet-office.gov.uk",
  "user:govsearchtest@gmail.com",
]
