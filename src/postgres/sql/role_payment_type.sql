SELECT
  url,
  details::json->>'role_payment_type' AS role_payment_type
FROM roles_details
WHERE details::json->>'role_payment_type' IS NOT NULL
;
