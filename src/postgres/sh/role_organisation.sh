# The organisation that each role belongs to
query_postgres \
  file=sql/role_organisation.sql \
| upload file_name=role_organisation
