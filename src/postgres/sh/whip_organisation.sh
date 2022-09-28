# The whip_organisation of every role that has it
query_postgres \
  file=sql/whip_organisation.sql \
| upload file_name=role_whip_organisation
