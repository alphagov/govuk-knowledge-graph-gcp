TRUNCATE TABLE search.organisation;
INSERT INTO search.organisation
WITH
parent_organisation AS (
  SELECT
    has_child_organisation.child_organisation_url AS url,
    ARRAY_AGG(DISTINCT parent_organisation.title) AS parentName,
  FROM graph.has_child_organisation
  LEFT JOIN graph.organisation AS parent_organisation ON parent_organisation.url = has_child_organisation.url
  GROUP BY has_child_organisation.child_organisation_url
),
child_organisations AS (
  SELECT
    has_child_organisation.url,
    ARRAY_AGG(organisation.title) AS childOrgNames
  FROM graph.has_child_organisation
  LEFT JOIN graph.organisation ON organisation.url = has_child_organisation.child_organisation_url
  GROUP BY has_child_organisation.url
),
organisation_roles AS (
  SELECT
    belongs_to.organisation_url AS url,
    ARRAY_AGG(
      STRUCT(
        role.title AS roleName,
        person.title AS personName
      )
    ) AS personRoleNames
  FROM graph.has_role
  LEFT JOIN graph.role ON role.url = has_role.role_url
  LEFT JOIN graph.belongs_to ON belongs_to.role_url = has_role.role_url
  LEFT JOIN graph.person ON person.url = has_role.person_url
  WHERE has_role.ended_on IS NULL -- the role-appointment is current
  GROUP BY
    belongs_to.organisation_url
),
superseded_by AS (
  SELECT
    has_successor.url,
    ARRAY_AGG(successor.title) AS supersededBy
  FROM graph.has_successor
  INNER JOIN graph.organisation AS successor ON successor.url = has_successor.successor_url
  GROUP BY has_successor.url
),
supersedes AS (
  SELECT
    has_successor.successor_url AS url,
    ARRAY_AGG(successee.title) AS supersedes
  FROM graph.has_successor
  INNER JOIN graph.organisation AS successee ON successee.url = has_successor.url
  GROUP BY has_successor.successor_url
)
SELECT
  organisation.title AS name,
  has_homepage.homepage_url AS homepage,
  parent_organisation.parentName,
  child_organisations.childOrgNames,
  organisation_roles.personRoleNames,
  superseded_by.supersededBy,
  supersedes.supersedes
FROM graph.organisation
LEFT JOIN graph.has_homepage USING (url)
LEFT JOIN parent_organisation USING (url)
LEFT JOIN child_organisations USING (url)
LEFT JOIN supersedes USING (url)
LEFT JOIN superseded_by USING (url)
LEFT JOIN organisation_roles USING (url)

-- name: string,
-- homepage: string,
-- description: string,
-- parentName: string,
-- childOrgNames: string[],
-- personRoleNames: {
--   personName: string,
--   roleName: string
-- }[],
-- supersededBy: string[],
-- supersedes: string[]
