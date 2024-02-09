SELECT
  url,
  CONCAT('https://www.gov.uk', base_path) AS homepage_url
FROM roles
WHERE base_path IS NOT NULL
;
