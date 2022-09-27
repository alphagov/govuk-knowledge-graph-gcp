# The content_id of every role and role appointment
query_postgres \
  file=sql/content_id.sql \
| upload file_name=role_content_id
