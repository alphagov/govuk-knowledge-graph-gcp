# The phase of every role and role appointment
query_postgres \
  file=sql/phase.sql \
| upload file_name=role_phase
