environment                = "production"
project_id                 = "govuk-knowledge-graph"
project_number             = "19513753240"
govgraph_domain            = "govgraph.dev"
govgraphsearch_domain      = "govgraphsearch.dev"
govsearch_domain            = "gov-search.service.gov.uk"
application_title          = "GovGraph Search"

govgraphsearch_iap_members = [
  "domain:digital.cabinet-office.gov.uk",

  # We want to allow trade.gov.uk, and when we do, Google silently respells it as
  # bis.gov.uk, presumably because of some DNS registration by BEIS as part of a
  # machinery of government change.
  "domain:bis.gov.uk",
]
