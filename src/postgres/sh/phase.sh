FILE_NAME=role_phase

# The phase of every role and role appointment
query_postgres \
  file=sql/phase.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
