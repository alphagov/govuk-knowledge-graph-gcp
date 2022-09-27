# The title of every role and role appointment
query_postgres \
  file=sql/title.sql \
| upload file_name=role_title
