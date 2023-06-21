environment                         = "production"
project_id                          = "govuk-knowledge-graph"
project_number                      = "19513753240"
govgraph_domain                     = "govgraph.dev"
govgraphsearch_domain               = "govgraphsearch.dev"
govsearch_domain                    = "gov-search.service.gov.uk"
application_title                   = "GovGraph Search"
enable_auth                         = "false"
signon_url                          = "https://signon.publishing.service.gov.uk"
oauth_auth_url                      = "https://signon.publishing.service.gov.uk/oauth/authorize"
oauth_token_url                     = "https://signon.publishing.service.gov.uk/oauth/access_token"
oauth_callback_url                  = "https://govgraphsearch.dev/auth/gds/callback"
enable_redis_session_store_instance = false
govgraphsearch_iap_members = [
  "domain:digital.cabinet-office.gov.uk",

  # We want to allow trade.gov.uk, and when we do, Google silently respells it as
  # bis.gov.uk, presumably because of some DNS registration by BEIS as part of a
  # machinery of government change.
  "domain:bis.gov.uk",

  # Users at DIT (Department for International Trade) use a different domain to
  # access Google services, so we allow this as well.
  "domain:digital.bis.gov.uk",

  # Users at MoJ (Ministry of Justice) use two different domains, and we don't
  # know which one is a Google domain, so we allow both.
  "domain:justice.gov.uk",
  "domain:digital.justice.gov.uk"
]
