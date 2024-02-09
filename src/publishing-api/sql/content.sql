WITH content AS (
  SELECT
  url,
  content as govspeak
FROM
  roles,
  jsonb_to_recordset(details->'body') AS content(content text, content_type text)
WHERE
  roles.schema_name = 'role'
  and content_type = 'text/govspeak'
)
SELECT row_to_json(content)
FROM content
;
