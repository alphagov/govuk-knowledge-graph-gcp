FILE_NAME=role_description

# The description of every role and role appointment
query_postgres \
  file=sql/description.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
