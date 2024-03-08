-- Call a sequence of routines that refresh tables in the legacy `graph`
-- dataset.

CALL graph.is_tagged_to();
CALL graph.page();
CALL graph.taxon();
