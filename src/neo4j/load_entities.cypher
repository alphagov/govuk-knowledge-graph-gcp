// "hamed_entities_counts.csv" contains entities extracted from
// mainstream content items using a fined-tuned RoBERTa model (https://arxiv.org/abs/1907.11692).
// This file is computed by a separate pipeline (https://github.com/alphagov/govuk-content-metadata) and fetched from S3,
// i.e. it's not generated as part of the build_knowledge_graph_data process
// Fields:
// - url	STRING
// - name_lower	STRING
// - type	STRING
// - url_entity_nametype	STRING
// - title_count	INTEGER
// - description_count	INTEGER
// - text_count	INTEGER
// - total_count	INTEGER

// Create unique node property constraint for NamedEntity urls
// Note that this also creates an index on that property (i.e., url)
// Ref: https://neo4j.com/docs/cypher-manual/current/constraints/
// See also: https://neo4j.com/docs/cypher-manual/current/indexes-for-search-performance/
CREATE CONSTRAINT UniqueNamedEntityUrl IF NOT EXISTS
FOR (e:NamedEntity)
REQUIRE e.url IS UNIQUE;

// Load entities and create relationships
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM "file:///named_entities_counts.csv" AS line
FIELDTERMINATOR ','
MATCH (p:Page {url: line.url})
MERGE (e:NamedEntity {name: line.name_lower, type: line.type, url:
line.url_entity_nametype})
CREATE (p)-[:HAS_NAMED_ENTITY{total_count:toInteger(line.total_count),
title_count:toInteger(line.title_count),
description_count:toInteger(line.description_count),
text_count:toInteger(line.text_count)}]->(e)
;
