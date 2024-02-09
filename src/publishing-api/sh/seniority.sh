FILE_NAME=role_seniority

query_postgres \
  file=sql/seniority.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
