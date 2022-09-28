# The role_payment_type of every role that has it
query_postgres \
  file=sql/role_payment_type.sql \
| upload file_name=role_role_payment_type
