-- Create links between roles and organisations
TRUNCATE TABLE graph.belongs_to;
INSERT INTO graph.belongs_to
SELECT
  *
FROM content.role_organisation
