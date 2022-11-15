// "ner_phase1_roberta_entities.csv" below is a CSV file containing entities extracted from
// mainstream content items using a fined-tuned RoBERTa model (https://arxiv.org/abs/1907.11692).
// This file is computed by a separate pipeline (https://github.com/alphagov/govuk-content-metadata) and fetched from S3,
// i.e. it's not generated as part of the build_knowledge_graph_data process
// Fields:
// entity_inst: lower-cased string that was tagged as an entity (e.g., "hmrc");
//      Example, if for text "You can contact HMRC" the model correctly picked up "HMRC" as an ORG entity type,
//      i.e., ("UK", "ORG", 16, 19), the entity_inst here would be "hmrc"
// entity_type: entity class (e.g., "ORG")
// entity_hash: hash of the combination of entity_name and entity_type;
//      A unique Hash was generated for each unique combination of (entity instance, entity type), so for each
//      unique combination of lower-cased entity string and tagged entity type, e.g., ("hmrc", "ORG").
//      This means that, for instance, ("asif khan", "PERSON") and ("asif khan", "ORG") will have a different Hash.
// base_path: base path of the Page
// title_count: count of occurrences of the (entity instance, entity type) pair in the title of the base_path
// description_count: count of occurrences of the (entity instance, entity type) pair in the description of the base_path
// text_count: count of occurrences of the (entity instance, entity type) pair in the main body text of the base_path
// total_count: total count of occurrences of the (entity instance, entity type) pair anywhere in the base_path


// Create unique node property constraint for NamedEntity urls
// Note that this also creates an index on that property (i.e., url)
// Ref: https://neo4j.com/docs/cypher-manual/current/constraints/
// See also: https://neo4j.com/docs/cypher-manual/current/indexes-for-search-performance/
CREATE CONSTRAINT UniqueNamedEntityUrl IF NOT EXISTS
FOR (e:NamedEntity)
REQUIRE e.url IS UNIQUE;


// Load entities and create relationships
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///ner_phase1_roberta_entities.csv" AS line
FIELDTERMINATOR ','
MATCH (p:Page {url: 'https://www.gov.uk' + line.base_path})
MERGE (e:NamedEntity {name: line.entity_inst, type: line.entity_type, url: 'https://www.gov.uk/named-entity/' + line.entity_hash})
CREATE (p)-[:HAS_NAMED_ENTITY{total_count:toInteger(line.total_count),
title_count:toInteger(line.title_count),
description_count:toInteger(line.description_count),
text_count:toInteger(line.text_count)}]->(e)
;
