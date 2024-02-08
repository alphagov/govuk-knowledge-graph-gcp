FILE_NAME=appointment_started_on

# When a role appointment started
query_postgres \
  file=sql/appointment_started_on.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
