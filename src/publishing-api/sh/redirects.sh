FILE_NAME=role_redirect

# Roles that have been redirected
query_postgres \
  file=sql/redirects.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
