# When a role appointment ended
query_postgres \
  file=sql/appointment_ended_on.sql \
| upload file_name=appointment_ended_on
