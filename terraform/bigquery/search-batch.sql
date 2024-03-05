-- Call a sequence of routines that refresh tables in the `search` dataset for
-- the GovSearch app.

CALL search.document_type();
CALL search.locale();
CALL search.organisation();
CALL search.taxon();
