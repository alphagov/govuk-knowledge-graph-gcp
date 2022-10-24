// Page-to-page transitions from Google Analytics (GA4, BigQuery)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///page_to_page_transitions_000000000000.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from_url })
MATCH (q:Page { url: line.to_url })
CREATE (p)-[:USER_MOVEMENT{
  numberOfMovements: toInteger(line.number_of_movements),
  numberOfUserPseudoIds: toInteger(line.number_of_user_pseudo_ids),
  numberOfSessions: toInteger(line.number_of_sessions)
}]->(q)
;
