# The locale of every role and role appointment
query_postgres \
  file=sql/locale.sql \
| upload file_name=role_locale
