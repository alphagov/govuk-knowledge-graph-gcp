# The url of every role
query_postgres \
  file=sql/role_url.sql \
| upload file_name=role_url
