# Technical debt

## 'Knowledge Graph'

It was once thought that a knowledge graph of the kind made famous by Google
Search and Wikidata could be useful for GOV.UK.  Current practical uses of the
data resemble typical analytical tasks, so the data is currently in a typical
relational structure.

## GitHub repository name

The name of this repository is `govuk-knowledge-graph-gcp` instead of
`govuk-knowledge-graph` because it was originally an experimental
reimplementation of https://github.com/alphagov/govuk-knowledge-graph, using GCP
(Google Cloud Platform) instead of AWS.

## Legacy datasets

The datasets `content` and `graph` in BigQuery have been deprecated, and remain
to support existing uses until they can be adapted to use the other datasets.
The `graph` dataset was so named because its tables were originally intended to
be imported into Neo4j, which is a graph database.  The `content` dataset was
so-named in anticipation of including data other than GOV.UK content data.
