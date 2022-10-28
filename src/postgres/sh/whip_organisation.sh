FILE_NAME=role_whip_organisation

# The whip_organisation of every role that has it
query_postgres \
  file=sql/whip_organisation.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
