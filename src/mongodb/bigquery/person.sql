DELETE graph.person WHERE TRUE;
INSERT INTO graph.person
SELECT
  'https://www.gov.uk/' || content_id AS url,
  title,
  content_id
FROM graph.page
WHERE
  TRUE
  AND document_type = 'person'
  AND locale = 'en'
;
