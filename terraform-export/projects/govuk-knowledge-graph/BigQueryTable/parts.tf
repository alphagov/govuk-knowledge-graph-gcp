resource "google_bigquery_table" "parts" {
  dataset_id    = "content"
  description   = "URLs, base_paths, slugs, indexes and titles of parts of guide and travel_advice documents"
  friendly_name = "URLs and titles of parts of guide and travel_advice documents"
  project       = "govuk-knowledge-graph"
  schema        = "[{\"description\":\"Complete URL of the part\",\"mode\":\"REQUIRED\",\"name\":\"url\",\"type\":\"STRING\"},{\"description\":\"URL of the parent document of the part\",\"mode\":\"REQUIRED\",\"name\":\"base_path\",\"type\":\"STRING\"},{\"description\":\"What to add to the base_path to get the url\",\"mode\":\"REQUIRED\",\"name\":\"slug\",\"type\":\"STRING\"},{\"description\":\"The order of the part among other parts in the same document, counting from 0\",\"mode\":\"REQUIRED\",\"name\":\"part_index\",\"type\":\"STRING\"},{\"description\":\"The title of the part\",\"mode\":\"REQUIRED\",\"name\":\"part_title\",\"type\":\"STRING\"}]"
  table_id      = "parts"
}
# terraform import google_bigquery_table.parts projects/govuk-knowledge-graph/datasets/content/tables/parts
