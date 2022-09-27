# The first_published_at of every role and role appointment
query_postgres \
  file=sql/first_published_at.sql \
| upload file_name=role_first_published_at
