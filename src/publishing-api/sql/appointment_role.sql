SELECT
  CONCAT('https://www.gov.uk/', role_appointments.content_id ) AS appointment_url,
  CONCAT('https://www.gov.uk/', links.target_content_id ) AS role_url
FROM role_appointments
INNER JOIN link_sets ON link_sets.content_id = role_appointments.content_id
INNER JOIN links ON links.link_set_id = link_sets.id
WHERE links.link_type = 'role'
;
