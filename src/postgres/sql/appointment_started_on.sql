SELECT
  url,
  (details::json->>'started_on') AS started_on
FROM role_appointments
;
