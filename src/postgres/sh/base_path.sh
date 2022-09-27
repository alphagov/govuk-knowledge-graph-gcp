# The base_path of every role and role appointment
query_postgres \
  file=sql/base_path.sql \
| upload file_name=role_base_path
