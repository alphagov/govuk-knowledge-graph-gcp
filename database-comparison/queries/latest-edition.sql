-- The most recent edition of each document, as long as it has a base_path (url)
DROP TABLE IF EXISTS editions_latest;
CREATE TABLE editions_latest AS
SELECT DISTINCT ON (document_id) *
FROM editions
WHERE base_path IS NOT NULL
ORDER BY document_id, updated_at DESC
;
