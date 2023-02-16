DELETE FROM search.transaction WHERE TRUE;
INSERT INTO search.transaction
SELECT
  title AS name,
  url AS homepage,
  description,
  start_button_text.start_button_text,
  transaction_start_link.link_url AS start_button_link
FROM graph.page
LEFT JOIN content.start_button_text USING (url)
LEFT JOIN content.transaction_start_link USING (url)
WHERE document_type = "transaction"
