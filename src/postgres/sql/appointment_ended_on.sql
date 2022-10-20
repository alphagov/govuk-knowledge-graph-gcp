SELECT
  url,
  (details::json->>'ended_on') AS ended_on
FROM role_appointments
WHERE details::jsonb ? 'ended_on'
;
