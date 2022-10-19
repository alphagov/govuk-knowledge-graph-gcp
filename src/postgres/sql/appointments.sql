DROP TABLE IF EXISTS role_appointments;
CREATE TABLE role_appointments AS
  SELECT
    CONCAT('https://www.gov.uk/', documents.content_id) AS url,
    documents.content_id,
    editions.details
  FROM editions
  INNER JOIN documents ON documents.id = editions.document_id
  WHERE
    document_type = 'role_appointment'
    AND content_store = 'live'
    AND editions.state = 'published'
    AND documents.locale = 'en'
;
