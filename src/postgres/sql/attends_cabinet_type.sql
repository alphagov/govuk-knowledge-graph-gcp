SELECT
  url,
  details::json->>'attends_cabinet_type' AS attends_cabinet_type
FROM roles_details
WHERE details::json->>'attends_cabinet_type' IS NOT NULL
;
