SELECT
  url,
  schema_name
FROM roles
WHERE schema_name IS NOT NULL
;
