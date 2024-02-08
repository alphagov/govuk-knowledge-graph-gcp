FILE_NAME=role_document_type

# The document_type of every role and role appointment
query_postgres \
  file=sql/document_type.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
