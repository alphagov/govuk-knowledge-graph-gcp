FILE_NAME=role_organisation

# The organisation that each role belongs to
query_postgres \
  file=sql/role_organisation.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
