-- The most recent non-draft edition of each document, as long as it has a
-- base_path (url)
CREATE TABLE IF NOT EXISTS editions_latest AS
SELECT DISTINCT ON (base_path) *
FROM editions
WHERE TRUE
AND base_path IS NOT NULL
AND state <> 'draft'
ORDER BY base_path, updated_at DESC
;
