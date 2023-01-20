# GOV.UK Knowledge Graph

Experiment with setting up a graph database containing (most of) the GOV.UK
content as a network of pages and hyperlinks, as well as other more "semantic"
objects such as Person or Organisation and relationships between them.

[This
version](https://console.cloud.google.com/welcome?project=govuk-knowledge-graph)
of the Knowledge Graph is hosted on GCP (Google Cloud Platform). It replaces a
[previous version](https://github.com/alphagov/govuk-knowledge-graph) that was
hosted on AWS (Amazon Web Services).

## Documentation

[GOV.UK Data Community Technical Documentation](https://docs.data-community.publishing.service.gov.uk/analysis/govgraph/pipeline-v2/)

## Links to GCP projects

* [Production](https://console.cloud.google.com/welcome?project=govuk-knowledge-graph)
* [Staging](https://console.cloud.google.com/welcome?project=govuk-knowledge-graph-staging)
* [Development](https://console.cloud.google.com/welcome?project=govuk-knowledge-graph-dev)

## IAM roles/permissions required in other projects

The following service accounts in each environment (prod, staging, dev) require
the following roles in the production environments of the following projects.

- `roles/storage.objectViewer` in `govuk-s3-mirror` for the bucket
  `govuk-s3-mirror_govuk-integration-database-backups`, for the `gce_mongodb`
  and `gce_postgres` service accounts.
- `roles/bigquery.dataViewer` in `ga4-analytics-352613` for the dataset
  `analytics_330577055` for the `bigquery_page_transitions` service account.

## Dev environment

Copy `terraform/*.tf` into `terraform-dev`.

In the rest of the code:

* Search for `PROJECT_ID=` and change its value to `govuk-knowledge-graph-dev`
* Search for `PROJECT_ID ` and change its value to `govuk-knowledge-graph-dev`
* Search for `DOMAIN=` and change its value to `govgraphdev.dev`
* Search for `dbms.default_advertised_address=` in `docker/neo4j/neo4j.conf` and
  change its value to `govgraphdev.dev`.

## Licence

Unless stated otherwise, the codebase is released under [the MIT License][mit].
This covers both the codebase and any sample code in the documentation.

The documentation is [© Crown copyright][copyright] and available under the terms
of the [Open Government 3.0][ogl] licence.

[rvm]: https://www.ruby-lang.org/en/documentation/installation/#managers
[bundler]: http://bundler.io/
[mit]: LICENCE
[copyright]: http://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/
[ogl]: http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/
