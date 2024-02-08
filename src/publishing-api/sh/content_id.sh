FILE_NAME=role_content_id

# The content_id of every role and role appointment
query_postgres \
  file=sql/content_id.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
