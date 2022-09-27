SELECT
  url,
  first_published_at
FROM roles
WHERE first_published_at IS NOT NULL
;
