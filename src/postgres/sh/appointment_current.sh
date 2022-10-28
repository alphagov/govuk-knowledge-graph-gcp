FILE_NAME=appointment_current

# Whether a role appointment is current
query_postgres \
  file=sql/appointment_current.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
