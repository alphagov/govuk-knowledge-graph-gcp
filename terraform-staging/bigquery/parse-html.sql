CREATE OR REPLACE FUNCTION `${project_id}.functions.parse_html`(html STRING)
RETURNS JSON
REMOTE WITH CONNECTION `${project_id}.${region}.govspeak-to-html`
OPTIONS (
  endpoint = "${uri}",
  max_batching_rows=1
)
