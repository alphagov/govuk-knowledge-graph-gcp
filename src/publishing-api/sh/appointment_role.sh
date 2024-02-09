FILE_NAME=appointment_role

# Link between a role_appointment and a role
query_postgres \
  file=sql/appointment_role.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
