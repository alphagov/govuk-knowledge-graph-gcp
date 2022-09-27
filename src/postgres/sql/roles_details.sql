DROP TABLE IF EXISTS roles_details;
CREATE TABLE roles_details AS
  SELECT
    url,
    details
FROM roles
WHERE schema_name = 'role'
;
