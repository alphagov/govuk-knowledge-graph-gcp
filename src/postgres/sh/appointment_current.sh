# Whether a role appointment is current
query_postgres \
  file=sql/appointment_current.sql \
| upload file_name=appointment_current
