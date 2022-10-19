# When a role appointment started
query_postgres \
  file=sql/appointment_started_on.sql \
| upload file_name=appointment_started_on
