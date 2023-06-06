TRUNCATE TABLE search.person;
INSERT INTO search.person
WITH
role_organisations AS (
  SELECT
    has_role.person_url,
    role.title AS title,
    ARRAY_AGG(
      STRUCT(
        organisation.title AS orgName,
        has_homepage.homepage_url AS orgURL
      )
      IGNORE NULLS
    ) AS orgs,
    has_role.started_on AS startDate,
    has_role.ended_on AS endDate
  FROM graph.has_role
  LEFT JOIN graph.role ON role.url = has_role.role_url
  LEFT JOIN graph.belongs_to ON belongs_to.role_url = has_role.role_url
  LEFT JOIN graph.organisation ON organisation.url = belongs_to.organisation_url
  LEFT JOIN graph.has_homepage ON has_homepage.url = belongs_to.organisation_url
  GROUP BY
    has_role.role_url,
    has_role.person_url,
    role.title,
    has_role.started_on,
    has_role.ended_on
),
person_roles AS (
  SELECT
    person_url,
    ARRAY_AGG(STRUCT(title, orgs, startDate, endDate)) AS roles
  FROM role_organisations
  GROUP BY person_url
)
SELECT
  person.title AS name,
  has_homepage.homepage_url AS homepage,
  person.description,
  person_roles.roles
FROM graph.person
LEFT JOIN graph.has_homepage ON has_homepage.url = person.url
LEFT JOIN person_roles ON person_roles.person_url = person.url

-- type: MetaResultType,
-- name: string,
-- homepage: string,
-- description: string,
-- roles: {
--   title: string,
--   orgs: {
--     orgName: string,
--     orgUrl: string
--   }[]
--   startDate: Date,
--   endDate: Date | null
-- }[]
