DELETE graph.person WHERE TRUE;
INSERT INTO graph.person
SELECT
  'https://www.gov.uk/' || content_id AS url,
  title,
  content_id,
  description.description
FROM graph.page
LEFT JOIN content.description ON description.url = page.url
WHERE
  TRUE
  AND document_type = 'person'
  AND locale = 'en'
;
