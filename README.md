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

## Dev environment

* Redefine variables in `terraform-dev/main-gcp.tf`
  * `project_id`
  * `project_number`
  * `govgraph_domain`
  * `govgraph_static_ip_address`
* Redefine backend bucket name in `terraform-dev/backend.tf`
* Redefine `PROJECT_ID=govuk-knowledge-graph-dev` everywhere
* Redefine `DOMAIN=govgraphdev.dev` everywhere
* Redefine `dbms.default_advertised_address=govgraphdev.dev` in
  `docker/neo4j/neo4j.conf`.

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
