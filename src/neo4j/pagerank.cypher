// PAGERANK
// Run weighted PageRank to identify influential Pages
// This requires some sense check and exploration to determine whether it's suited to this approach

// Firstly, create projection of Page nodes and USER_MOVEMENT relationships with their weight
CALL gds.graph.project.cypher(
'page-user-movement',
'MATCH (n:Page) RETURN id(n) as id',
'MATCH (t)-[m:USER_MOVEMENT]-(g) RETURN id(t) AS source, id(g) AS target, type(m) as type, m.numberOfMovements as weight'
);

// Calculate pagerank on the projection
CALL gds.pageRank.write('page-user-movement', {
  maxIterations: 20,
  dampingFactor: 0.85,
  writeProperty: 'pagerank',
  relationshipTypes: ['USER_MOVEMENT'],
  relationshipWeightProperty: 'weight'
})
YIELD nodePropertiesWritten, ranIterations
RETURN count(nodePropertiesWritten);

// We don't need this projection any more so drop it
CALL gds.graph.drop('page-user-movement') YIELD graphName;
