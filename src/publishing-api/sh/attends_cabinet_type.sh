FILE_NAME=role_attends_cabinet_type

query_postgres \
  file=sql/attends_cabinet_type.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
