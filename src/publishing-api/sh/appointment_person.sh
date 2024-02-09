FILE_NAME=appointment_person

# Link between a role_appointment and a role
query_postgres \
  file=sql/appointment_person.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
