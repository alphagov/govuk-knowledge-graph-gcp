CREATE OR REPLACE FUNCTION `${project_id}.functions.embed_text`(text STRING)
RETURNS JSON
REMOTE WITH CONNECTION `${project_id}.${region}.embed-text`
OPTIONS (
  endpoint = "${uri}",
  max_batching_rows=1
)
