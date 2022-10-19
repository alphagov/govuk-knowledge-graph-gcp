SELECT
  role_appointments.content_id AS role_appointment_content_id,
  links.target_content_id AS role_content_id
FROM role_appointments
INNER JOIN link_sets ON link_sets.content_id = role_appointments.content_id
INNER JOIN links ON links.link_set_id = link_sets.id
WHERE links.link_type = 'role'
;
