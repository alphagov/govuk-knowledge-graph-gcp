FILE_NAME=role_homepage_url

# The homepage of roles and role appointments that have them
query_postgres \
  file=sql/homepage_url.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
