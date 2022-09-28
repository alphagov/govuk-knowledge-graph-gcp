SELECT
  url,
  public_updated_at
FROM roles
WHERE public_updated_at IS NOT NULL
;
