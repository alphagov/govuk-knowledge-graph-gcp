-- Table of things on GOV.UK, and the type of thing that they are
DELETE FROM search.entityTypes WHERE TRUE;
INSERT INTO search.entityTypes
SELECT DISTINCT
  type
FROM `cpto-content-metadata.named_entities.named_entities_counts`
;
