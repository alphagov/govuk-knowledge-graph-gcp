FILE_NAME=role_first_published_at

# The first_published_at of every role and role appointment
query_postgres \
  file=sql/first_published_at.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
