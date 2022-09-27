# The public_updated_at of every role and role appointment
query_postgres \
  file=sql/public_updated_at.sql \
| upload file_name=role_public_updated_at
