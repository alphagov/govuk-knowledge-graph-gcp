SELECT
  url,
  details::json->>'role_payment_type' AS role_payment_type
FROM roles
WHERE details::json->>'role_payment_type' IS NOT NULL
;
