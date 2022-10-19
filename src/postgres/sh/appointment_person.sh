# Link between a role_appointment and a role
query_postgres \
  file=sql/appointment_person.sql \
| upload file_name=appointment_person
