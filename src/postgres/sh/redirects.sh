# Roles that have been redirected
query_postgres \
  file=sql/redirects.sql \
| upload file_name=role_redirects
