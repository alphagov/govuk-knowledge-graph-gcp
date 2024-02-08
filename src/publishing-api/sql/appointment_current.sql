SELECT
  url,
  (details::json->>'current') AS current
FROM role_appointments
WHERE details::jsonb ? 'current'
;
