FILE_NAME=role_url

# The url of every role
query_postgres \
  file=sql/role_url.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
