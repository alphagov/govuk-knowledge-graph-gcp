# The publishing_app of every role and role appointment
query_postgres \
  file=sql/publishing_app.sql \
| upload file_name=role_publishing_app
