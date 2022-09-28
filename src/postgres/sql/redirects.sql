SELECT
  CONCAT('https://www.gov.uk/roles/', editions.base_path) AS from,
  unpublishings.alternative_path AS to
FROM editions
INNER JOIN unpublishings ON unpublishings.edition_id = editions.id
WHERE
  editions.schema_name = 'role'
  AND editions.content_store = 'live'
  AND editions.state = 'unpublished'
  AND unpublishings.type = 'redirect'
;
