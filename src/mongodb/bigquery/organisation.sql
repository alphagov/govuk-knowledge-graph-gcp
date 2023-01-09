-- Derive organisations, persons, and taxons
DELETE graph.organisation WHERE TRUE;
INSERT INTO graph.organisation
SELECT
  'https://www.gov.uk/' || content_id AS url,
  title,
  analytics_identifier,
  content_id,
  phase,
  acronym
FROM graph.page
WHERE
  TRUE
  AND document_type = 'organisation'
  AND locale = 'en'
;
