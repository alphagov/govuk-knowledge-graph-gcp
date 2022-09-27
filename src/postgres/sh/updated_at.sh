# The updated_at of every role and role appointment
query_postgres \
  file=sql/updated_at.sql \
| upload file_name=role_updated_at
