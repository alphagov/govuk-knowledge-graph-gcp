# The description of every role and role appointment
query_postgres \
  file=sql/description.sql \
| upload file_name=role_description
