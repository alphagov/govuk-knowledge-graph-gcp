-- Create links between people and roles
DELETE FROM graph.has_role WHERE TRUE;
INSERT INTO graph.has_role
SELECT
  appointment_person.person_url AS person_url,
  appointment_role.role_url AS role_url,
  appointment_started_on.started_on,
  appointment_ended_on.ended_on
FROM content.appointment_url
LEFT JOIN content.appointment_current USING (url)
LEFT JOIN content.appointment_started_on USING (url)
LEFT JOIN content.appointment_ended_on USING (url)
INNER JOIN content.appointment_person ON appointment_person.appointment_url = appointment_url.url
INNER JOIN content.appointment_role ON appointment_role.appointment_url = appointment_url.url
;
