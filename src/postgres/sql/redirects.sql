SELECT
  CONCAT('https://www.gov.uk', editions.base_path) AS from,
  CONCAT('https://www.gov.uk', unpublishings.alternative_path) AS to
FROM editions
INNER JOIN unpublishings ON unpublishings.edition_id = editions.id
WHERE
  editions.schema_name = 'role'
  AND editions.content_store = 'live'
  AND editions.state = 'unpublished'
  AND unpublishings.type = 'redirect'
;
