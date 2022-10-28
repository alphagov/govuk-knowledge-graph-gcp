FILE_NAME=appointment_url

# The url of every role appointment
query_postgres \
  file=sql/appointment_url.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
