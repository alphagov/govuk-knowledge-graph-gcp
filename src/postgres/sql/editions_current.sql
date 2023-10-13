-- The most recent non-draft edition of each document.
-- A document is a unique pair of content_id and locale.
-- Doesn't necessarily have a base_path, e.g. role and role_appointment
-- documents
DROP TABLE IF EXISTS editions_current;
CREATE TABLE editions_current AS
SELECT DISTINCT ON (document_id)
  documents.content_id,
  documents.locale,
  editions.*
FROM editions
INNER JOIN documents ON documents.id = editions.document_id
WHERE state <> 'draft'
ORDER BY
  editions.document_id,
  editions.updated_at DESC,
  editions.user_facing_version DESC
;

SELECT * FROM editions_current;
