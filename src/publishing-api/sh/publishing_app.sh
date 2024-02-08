FILE_NAME=role_publishing_app

# The publishing_app of every role and role appointment
query_postgres \
  file=sql/publishing_app.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
