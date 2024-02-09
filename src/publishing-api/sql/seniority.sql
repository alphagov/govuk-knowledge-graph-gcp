SELECT
  url,
  (details::json->>'seniority')::int AS seniority
FROM roles
WHERE (details::json->>'seniority')::int IS NOT NULL
;
