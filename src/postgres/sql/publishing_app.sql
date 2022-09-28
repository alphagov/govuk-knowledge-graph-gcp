SELECT
  url,
  publishing_app
FROM roles
WHERE publishing_app IS NOT NULL
;
