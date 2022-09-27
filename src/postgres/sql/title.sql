SELECT
  url,
  title
FROM roles
WHERE title IS NOT NULL
AND title <> ''
;
