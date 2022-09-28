# The document_type of every role and role appointment
query_postgres \
  file=sql/document_type.sql \
| upload file_name=role_document_type
