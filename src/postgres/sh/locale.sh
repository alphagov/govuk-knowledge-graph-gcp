FILE_NAME=role_locale

# The locale of every role and role appointment
query_postgres \
  file=sql/locale.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
