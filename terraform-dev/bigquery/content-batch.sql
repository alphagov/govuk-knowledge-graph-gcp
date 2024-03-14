-- Call a sequence of routines that refresh tables in the legacy `content`
-- dataset.

CALL content.content();
CALL content.base_path_lookup(); -- Depends on results of content.content();
CALL content.description();
CALL content.expanded_links();
CALL content.lines();
CALL content.title();
