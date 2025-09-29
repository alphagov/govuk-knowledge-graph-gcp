# GOV.UK Knowledge Graph

* GOV.UK content data in BigQuery, for analytical workloads.
* Cloud infrastructure for the [GovSearch][govsearch] app.

## Documentation

Most documentation is in `README.md` files and [`docs`][docs] directory in this repository.  There is also [GOV.UK Data Community Technical Documentation][data-community-docs].

## Data pipeline overview

1. A workflow subscribes to notifications from the GOV.UK S3 Mirror that a new database backup of the Publishing API is available.  The workflow creates an instance of a virtual machine.
2. The virtual machine fetches the database backup file, extracts its data, and uploads that into BigQuery.
3. Some SQL queries are scheduled to run daily, which call other SQL routines to refresh various tables from the newly uploaded data.

## Access and permissions

People are granted access by membership of Google Groups.  Other Google Cloud Platform projects are granted access via service accounts.  Access is granted by editing each environment's tfvars file, such as `terraform-dev/environment.auto.tfvars`.

### Google Groups

* [govgraph-private-data-viewers](https://groups.google.com/a/digital.cabinet-office.gov.uk/g/govsearch-data-viewers/about) has `roles/bigquery.dataViewer` in relation to each BigQuery dataset except 'test', and `roles/bigquery.jobUser` to be able to run queries that are billed to the billing account of the `govuk-knowledge-graph*` projects.
* [govgraph-developers](https://groups.google.com/a/digital.cabinet-office.gov.uk/g/govsearch-developers/members) has the `roles/owner` role in relation to each `govuk-knowledge-graph*` project.

### IAM roles/Permissions required in other projects

#### govuk-s3-mirror

Search for `govuk-knowledge-graph` in https://github.com/alphagov/govuk-s3-mirror to see what permissions are granted there. That project also publishes to Pub/Sub topics in this project.

#### gds-bq-reporting

The service accounts that this project uses to publish logs to the `gds-bq-reporting` project must be given the `roles/logging.bucketWriter` role in that project.

## Tests

There are hardly any tests.

### SQL

The most likely cause of an error in GovSearch queries is a change to the data and document schemas in the Publishing API.

It is difficult, in general, to test chains of SQL statements.  DBT is popular for doing so, but adds a considerable abstraction, as well as requiring Python, which is discouraged in GOV.UK.

A [scheduled query][scheduled-query] runs every hour, and raises an error if any tables have zero rows or have not been updated in the past 25 hours.  The error is automatically detected in the logs, and an [alert][alert] is raised, which sends an email to the [govsearch-developers][govsearch-developers] Google Group.  Once the problem has been addressed, close the issue.

### Ruby

Two of the BigQuery Remote Functions are implemented in Ruby and have unit tests.  They are [parse-html](./src/cloud-functions/parse-html) and [html-to-text](./docker/html-to-text).  Other BigQuery Remote Functions are somewhat trivial.

## Maintainers

This project is maintained by the GOV.UK team, which is part of the Government Digital Service.

## Common tasks

### Import data from somewhere new

Look at https://github.com/alphagov/govuk-knowledge-graph-gcp/pull/594, which derives data from the Publisher app database and puts it into BigQuery.

## Troubleshooting

### Outdated or empty BigQuery tables

If GovSearch gives unexpected results, then the tables in BigQuery might not have been updated correctly.  Usually that means a table either hasn't been updated at all within the last 24 hours, or it has been updated and is now empty.  You can quickly check every table by querying a view called `test.tables-metadata` by writing a query like `SELECT * FROM test.tables-metadata;`. The table is checked automatically every hour, and if it finds old or empty tables then an 'incident' is created, and an email is sent to govgraph-developers@digital.cabinet-office.gov.uk.

### Source data glitch

Check that the database backup files in the [govuk-s3-mirror][govuk-s3-mirror] are the expected size (many gigabytes) by looking in the [bucket](https://console.cloud.google.com/storage/browser/govuk-s3-mirror_govuk-database-backups?project=govuk-s3-mirror).

Check that the Publishing API hasn't changed its schemas.

## Other representations of GOV.UK content

There are several different representations of GOV.UK content, including:

- Publishing API
- Content Store
- Search API
- CDN cache (content delivery network)
- Mirror (HTML pages crawled nightly)
- National Archives (snapshots of content over time)

None of these representations met a need for advanced searching and filtering for content designers, or a need for low-level structured data for developing data science applications.  Hence the Knowledge Graph was developed.

## Technical debt

See [Technical debt][technical-debt].

## Contributing

You are welcome to:

- ask a question by opening an issue or by contacting the [maintainers](#maintainers).
- open an issue
- submit a pull request

## Deployment
This is not yet an exhaustive set of instructions as the deployment process is likely to change very soon at the time of writing. For now its main purpose to is to capture some of the "gotchas" you may experience during deployments which I have not found documented elsewhere.

### Terraform Gotchas

#### google_compute_instance_template
Various GCE templates are defined for the VMs (`resource google_compute_instance_template`).
Google periodically updates the base images upstream and so sometimes a `terraform plan/apply` may throw up a number of replacement changes to these resources. This is normal and the plan may be applied. However, it is worth monitoring this in dev just to be sure that no low-level binaries in the image cause breaking changes to the ingestion.

#### google_cloud_run_service.govgraphsearch
The current deployment process configures most of the Cloud Run services in terraform. However, the deployment of new GovSearch revisions uses the `gcloud` cli in the CI. This can cause drift in some of the `run.googleapis.com/client-*` annotations and an apparent update to the image. The image will not be updated, just the tag used to pull it. These updates can be safely applied. This will create a new revision but you can verify that the image hash has not changed between revisions by checking the `spec.containers.image` property in the revision via the Cloud Run UI.

## Licence

Unless stated otherwise, the codebase is released under [the MIT License][mit]. This covers both the codebase and any sample code in the documentation.

The documentation is [© Crown copyright][copyright] and available under the terms of the [Open Government 3.0][ogl] licence.

[copyright]: http://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/
[cpto-content-metadata]: https://console.cloud.google.com/welcome?project=cpto-content-metadata
[docs]: docs
[ga4-analytics-352613]: https://console.cloud.google.com/welcome?project=govuk-bigquery-analytics
[govsearch]: https://github.com/alphagov/govuk-knowledge-graph-search
[govuk-s3-mirror]: https://github.com/alphagov/govuk-s3-mirror
[mit]: LICENCE
[ogl]: http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/
[technical-debt]: docs/technical-debt.md
[scheduled-query]: https://console.cloud.google.com/bigquery/scheduled-queries/locations/europe-west2/configs/646d78e5-0000-2cd4-94b2-94eb2c1b665a/runs?project=govuk-knowledge-graph
[alert]: https://console.cloud.google.com/monitoring/alerting?project=govuk-knowledge-graph
[govsearch-data-viewers]: https://groups.google.com/a/digital.cabinet-office.gov.uk/g/govsearch-data-viewers/about
[govsearch-developers]: https://groups.google.com/a/digital.cabinet-office.gov.uk/g/govsearch-developers/members
[data-community-docs]: https://gds-data-docs-bkbishsofa-nw.a.run.app/engineering/knowledge-graph-pipeline-v2/#advantages-of-the-new-pipeline
[govuk-s3-mirror]: https://github.com/alphagov/govuk-s3-mirror
