// Label non-www.gov.uk pages as external
MATCH (n:Page) WHERE left(n.url, 18) <> "https://www.gov.uk"
SET n:ExternalPage
REMOVE n:Page
;
