DROP TABLE IF EXISTS roles;
CREATE TABLE roles AS
  SELECT
    CONCAT('https://www.gov.uk/', documents.content_id) AS url,
    editions.schema_name,
    editions.document_type,
    editions.publishing_app,
    editions.phase,
    documents.content_id,
    documents.locale,
    editions.updated_at,
    editions.public_updated_at,
    editions.first_published_at,
    editions.base_path,
    editions.title,
    editions.description,
    editions.details
  FROM editions
  INNER JOIN documents ON documents.id = editions.document_id
  WHERE
    schema_name IN ('role', 'role_appointment')
    AND content_store = 'live'
    AND editions.state = 'published'
;
