USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_url.csv' AS line
FIELDTERMINATOR ','
CREATE (p:Role { url: line.url })
;

CREATE CONSTRAINT ON (p:Role) ASSERT p.url IS UNIQUE;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_document_type.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.documentType = line.document_type
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_phase.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.phase = line.phase
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_content_id.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.contentId = line.content_id
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_locale.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.locale = line.locale
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_publishing_app.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.publishingApp = line.publishing_app
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.updatedAt = line.updated_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_public_updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.publicUpdatedAt = line.public_updated_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_first_published_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.firstPublishedAt = line.first_published_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_title.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.name = line.title
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_description.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.description = line.description
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.text = line.text
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_redirect.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from })
MATCH (q:Page { url: line.to })
CREATE (p)-[r:REDIRECTS_TO]->(q)
;

// Link to home pages of roles that have base_paths
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_homepage_url.csv' AS line
FIELDTERMINATOR ','
MATCH (r:Role { url: line.url })
MATCH (p:Page { url: "https://www.gov.uk" + line.base_path, locale: 'en' })
CREATE (r)-[:HAS_HOMEPAGE]->(p)
;

// Create RoleAppointment nodes
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///appointment_url.csv' AS line
FIELDTERMINATOR ','
CREATE (p:RoleAppointment { url: line.url })
;

CREATE CONSTRAINT ON (p:RoleAppointment) ASSERT p.url IS UNIQUE;

// Create properties of role_appointments
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///appointment_current.csv' AS line
FIELDTERMINATOR ','
MATCH (p:RoleAppointment { url: line.url })
SET p.current = (case line.current when "t" then true else false end)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///appointment_started_on.csv' AS line
FIELDTERMINATOR ','
MATCH (p:RoleAppointment { url: line.url })
SET p.startedOn = line.started_on
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///appointment_ended_on.csv' AS line
FIELDTERMINATOR ','
MATCH (p:RoleAppointment { url: line.url })
SET p.endedOn = line.ended_on
;

// Create links between role_appointments and roles
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///appointment_role.csv' AS line
FIELDTERMINATOR ','
MATCH (p:RoleAppointment { url: line.appointment_url })
MATCH (q:Role { url: line.role_url })
CREATE (p)-[:LINKS_TO { linkTargetType: 'role' }]->(q)
;

// Create links between role_appointments and persons
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///appointment_person.csv' AS line
FIELDTERMINATOR ','
MATCH (p:RoleAppointment { url: line.appointment_url })
MATCH (q:Person { url: line.person_url })
CREATE (p)-[:LINKS_TO { linkTargetType: 'person' }]->(q)
;

// Reuse `role` and `person` links as `HAS_ROLE`.
MATCH (p:Person)<-[:LINKS_TO {linkTargetType: 'person'}]-(a:RoleAppointment)-[:LINKS_TO {linkTargetType: 'role'}]->(r:Role)
CREATE (p)-[:HAS_ROLE { startDate: a.startedOn, endDate: a.endedOn }]->(r)
;

// Create links between roles and organisations
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_organisation.csv' AS line
FIELDTERMINATOR ','
MATCH (r:Role { url: line.role_url })
MATCH (o:Organisation { url: line.organisation_url })
CREATE (o)-[:LINKS_TO { linkTargetType: 'ordered_roles' }]->(r)
CREATE (r)-[:BELONGS_TO]->(o)
;
