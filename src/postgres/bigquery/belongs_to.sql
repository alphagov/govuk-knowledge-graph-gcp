-- Create links between roles and organisations
DELETE FROM graph.belongs_to WHERE TRUE;
INSERT INTO graph.belongs_to
SELECT
  *
FROM content.role_organisation
