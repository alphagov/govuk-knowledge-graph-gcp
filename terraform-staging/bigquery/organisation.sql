TRUNCATE TABLE search.organisation;
INSERT INTO search.organisation
SELECT DISTINCT title.title
FROM content.title
INNER JOIN content.document_type USING (url)
INNER JOIN content.locale USING (url)
WHERE
  TRUE
  AND document_type.document_type = 'organisation'
  AND locale.locale = 'en'
