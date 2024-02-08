FILE_NAME=role_title

# The title of every role and role appointment
query_postgres \
  file=sql/title.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
