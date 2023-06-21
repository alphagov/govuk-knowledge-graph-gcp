# GOV.UK Knowledge Graph on GCP

GOV.UK content data and cloud infrastructure for the [GovSearch][govsearch] app.

The Knowledge Graph is a representation of GOV.UK content that suits:

- searching for exact string matches
- exploring relations between parts, such as pages that link to YouTube, or
  incumbents of roles in DEFRA
- training and using Named Entity Recognition models
- matching paragraphs within a page
- bulk usage

It is hosted on GCP (Google Cloud Platform). A [previous
implementation](https://github.com/alphagov/govuk-knowledge-graph) was hosted on
AWS (Amazon Web Services).

## Table of Contents

- [Background](#background)
- [Documentation](#documentation)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [Licence](#licence)

## Background

There are several different representations of GOV.UK content, including:

- Publishing API
- Content Store
- Search API
- CDN cache (content delivery network)
- Mirror (HTML pages crawled nightly)
- National Archives (snapshots of content over time)

None of these representations met a need for advanced searching and filtering
for content designers, or a need for low-level structured data for developing
data science applications.  Hence the Knowledge Graph was developed.

This implementation of the knowledge graph primarily uses data from the Content
Store, supplemented by other sources.  It has been developed to support the
[GovSearch][govsearch] app in particular, as well as to make structured content
data easily accessible in bulk.

## Documentation

[GOV.UK Data Community Technical Documentation](https://gds-data-docs-bkbishsofa-nw.a.run.app/engineering/knowledge-graph-pipeline-v2/#advantages-of-the-new-pipeline)

## Maintainers

This project is maintained by the Data Products team in the Data Services group
in the Product & Technology directorate in the Government Digital Service.
Contact them by email on data-products@digital.cabinet-office.gov.uk or via
their GDS slack channel `#data-products`.  The developers can be contacted more
directly by email on govsearch-developers@digital.cabinet-office.gov.uk.

## Contributing

You are welcome to:

- ask a question by opening an issue or by contacting the
  [maintainers](#maintainers).
- open an issue
- submit a pull request

## Licence

Unless stated otherwise, the codebase is released under [the MIT License][mit].
This covers both the codebase and any sample code in the documentation.

The documentation is [© Crown copyright][copyright] and available under the terms
of the [Open Government 3.0][ogl] licence.

[mit]: LICENCE
[copyright]: http://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/
[ogl]: http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/
[govsearch]: https://github.com/alphagov/govuk-knowledge-graph-search
[govuk-s3-mirror]: https://github.com/alphagov/govuk-s3-mirror
[ga4-analytics-352613]: https://console.cloud.google.com/welcome?project=govuk-bigquery-analytics
[cpto-content-metadata]: https://console.cloud.google.com/welcome?project=cpto-content-metadata
