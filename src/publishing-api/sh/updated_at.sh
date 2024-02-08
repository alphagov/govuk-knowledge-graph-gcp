FILE_NAME=role_updated_at

# The updated_at of every role and role appointment
query_postgres \
  file=sql/updated_at.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
