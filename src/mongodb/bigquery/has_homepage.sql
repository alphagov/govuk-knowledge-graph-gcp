-- Link each organisation, person, and taxon to its homepage
TRUNCATE TABLE graph.has_homepage;
INSERT INTO graph.has_homepage
SELECT
  'https://www.gov.uk/' || content_id AS url,
  url AS homepage_url
FROM graph.page
WHERE
  TRUE
  AND document_type IN ('organisation', 'person')
  AND locale = 'en'
;
INSERT INTO graph.has_homepage
SELECT
  url,
  homepage_url
FROM content.taxon_levels
;
