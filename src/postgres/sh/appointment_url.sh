# The url of every role appointment
query_postgres \
  file=sql/appointment_url.sql \
| upload file_name=appointment_url
