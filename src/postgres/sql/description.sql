SELECT
  url,
  description
FROM roles
WHERE description IS NOT NULL
AND description <> ''
;
