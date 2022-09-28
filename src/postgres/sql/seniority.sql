SELECT
  url,
  (details::json->>'seniority')::int AS seniority
FROM roles_details
WHERE (details::json->>'seniority')::int IS NOT NULL
;
