environment           = "development"
project_id            = "govuk-knowledge-graph-dev"
project_number        = "628722085506"
govgraph_domain       = "govgraphdev.dev"
govgraphsearch_domain = "govgraphsearchdev.dev"
govsearch_domain      = "gov-search.integration.service.gov.uk"
application_title     = "GovGraph Search (development)"
enable_auth           = "true"
signon_url            = "https://signon.integration.publishing.service.gov.uk"
oauth_auth_url        = "https://signon.integration.publishing.service.gov.uk/oauth/authorize"
oauth_token_url       = "https://signon.integration.publishing.service.gov.uk/oauth/access_token"
oauth_callback_url    = "https://govgraphsearchdev.dev/auth/gds/callback"
govgraphsearch_iap_members = [
  "allUsers"
]
enable_redis_session_store_instance = true
