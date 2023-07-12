FILE_NAME=role_schema_name

# The document_type of every role and role appointment
query_postgres \
  file=sql/schema_name.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
