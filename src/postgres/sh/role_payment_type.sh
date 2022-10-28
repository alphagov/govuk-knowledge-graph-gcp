FILE_NAME=role_payment_type

# The role_payment_type of every role that has it
query_postgres \
  file=sql/role_payment_type.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
