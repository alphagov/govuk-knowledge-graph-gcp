# The url of every role and role appointment
query_postgres \
  file=sql/url.sql \
| upload file_name=role_url
