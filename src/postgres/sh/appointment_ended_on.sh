FILE_NAME=appointment_ended_on

# When a role appointment ended
query_postgres \
  file=sql/appointment_ended_on.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
