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

[GOV.UK Data Community Technical Documentation](https://gds-data-docs-bkbishsofa-nw.a.run.app/engineering/knowledge-graph-pipeline-v2/#advantages-of-the-new-pipeline)

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
- `storage.objectViewer` in `cpto-content-metadata` for the bucket
  `cpto-content-metadata`, for the `gce_neo4j` and
  `bigquery_scheduled_queries_search` service accounts.

## Dev and staging environments

Push a local branch to the `dev` or `staging` branch, and GitHub actions will
deploy the changes to only that GCP project.  It won't deploy terraform, though,
so you should do that at the command line by doing

```sh
cd terraform-dev
terraform apply
```

Or

```sh
cd terraform-staging
terraform apply
```

## Things that can go wrong

### Outdated or empty BigQuery tables

If the web app gives unexpected results, then the tables in BigQuery might not
have been updated correctly.  Usually that means a table either hasn't been
updated at all within the last 24 hours, or it has been updated and is now
empty.  You can quickly check every table by querying a view called
`test.tables-metadata` by writing a query like `SELECT * FROM
test.tables-metadata;`.  Ideally we'd automate that check, and send an alert to
email and slack when any tables were outdated or empty, but we couldn't get it
to work, following the [official
docs](https://cloud.google.com/logging/docs/alerting/log-based-alerts).

### Source data glitch

Most of the data originates in GOV.UK as database backup files of the Publishing
API database (PostgreSQL) and the Content Store database (MongoDB).  Those files
are copied to a GCP bucket by the
[`govuk-s3-mirror`](https://github.com/alphagov/govuk-s3-mirror).  Check that
the files are the expected size (many gigabytes) by looking in the
[bucket](https://console.cloud.google.com/storage/browser/govuk-s3-mirror_govuk-integration-database-backups?project=govuk-s3-mirror).

### Some of the tables work but others don't

It isn't always clear which table didn't update correctly, because when
one table fails, sometimes the code stops running altogether, so other tables
that hadn't been attempted yet are never attempted.  This is because the code
that updates the tables is orchestrated by makefiles `src/mongodb/Makefile` and
`src/postgres/Makefile`, and when a step in a makefile fails, subsequent steps
aren't attempted, even if they don't depend on the step that failed.  An
additional complication is that the makefiles are configured to run several
steps in parallel, so when one step fails, any other steps that are still
running will finish.

In this situation, it's best to consult the
[logs](https://console.cloud.google.com/logs/query?project=govuk-knowledge-graph).
Unfortunately, [not everything is in the
logs](https://github.com/alphagov/govuk-knowledge-graph-gcp/issues/263), so
sometimes it's necessary to manually run the data process, SSH into the machine
that's running it, and tail the logs there.  See the section on running the data
pipelines manually.

### Running the data pipelines automatically

The data pipelines work automatically as follows:

1. The `govuk-s3-mirror` project obtains a new database backup file from GOV.UK,
   places it into a bucket, and publishes a notification to Pub/Sub.
2. A
   [workflow](https://console.cloud.google.com/workflows/workflow/europe-west2/govuk-integration-database-backups/executions?project=govuk-knowledge-graph)
   that subscribes to Pub/Sub checks whether the file is for MongoDB or
   Postgres, and if so, creates a new virtual machine instance from an [instance
   template](https://console.cloud.google.com/compute/instanceTemplates/list?project=govuk-knowledge-graph-staging)
   of mongodb or postgres.
3. The instance fetches a script
   ([docker/mongodb/run.sh](https://console.cloud.google.com/storage/browser/_details/govuk-knowledge-graph-dev-repository/docker/mongodb/run.sh),
   [postgres](https://console.cloud.google.com/storage/browser/_details/govuk-knowledge-graph-dev-repository/docker/postgres/run.sh)) and executes it.
4. The script tells the instance how to query the database, transform the results,
   upload the results to a
   [bucket](https://console.cloud.google.com/storage/browser/govuk-knowledge-graph-data-processed),
   and transfer the data from the bucket into BigQuery tables.
5. The script tells the instance to delete itself.

### Running the data pipelines manually

You can trigger a new virtual machine instance by manually re-executing the
[workflow](https://console.cloud.google.com/workflows/workflow/europe-west2/govuk-integration-database-backups/executions?project=govuk-knowledge-graph).
Choose a workflow run that previously successfully started mongodb or postgres
(whichever one you want to run).

You might want to prevent the instance from deleting itself when it has
finished.  One way to do that is to wait until it has started, and then revoke
its `compute.instanceAdmin.v1` IAM role.  Another way is to edit the `run.sh`
script to remove the line that deletes the instance, upload that version of the
script to the
[bucket](https://console.cloud.google.com/storage/browser/govuk-knowledge-graph-repository), and then trigger the instance.

Once the instance is running, you can SSH into it from your local device, in the
terminal.

```sh
# SSH into the instance that hosts the mongodb docker image
gcloud compute ssh --zone "europe-west2-b" "mongodb" --project "govuk-knowledge-graph"

# Or SSH into the instance that hosts the postgres docker image
gcloud compute ssh --zone "europe-west2-b" "postres" --project "govuk-knowledge-graph"

# Wait a while for the docker image to start (about 30 seconds to a minute)

# Get the ID of the docker image.
# Mongodb is usually klt--yhxe
# Postgres is usually klt--wttb
docker ps

# Tail the logs of the mongodb docker image
docker logs -tf klt--yhxe

# Tail the logs of the postgres docker image
docker logs -tf klt--wttb

# Otherwise, SSH directly from your device into the mongodb docker image
gcloud compute ssh --zone "europe-west2-b" "mongodb" --project "govuk-knowledge-graph" -- container "klt--yhxe"

# Or SSH directly from your device into the postgres docker image
gcloud compute ssh --zone "europe-west2-b" "postgres" --project "govuk-knowledge-graph" -- container "klt--wttb"
```

## Keeping terraform the same in all environments

The terraform configuration of each environment `terraform`,
`terraform-staging`, `terraform-dev` should be the same, apart from some
unavoidable differences, such as the project number and feature flags.  This
makes it easier to promote a change from one environment to another.  The
workflow envisaged by this system is:

1. Check out a new branch based on `main`.
1. Edit the terraform configuration of the environment that you're using, e.g.
   `terraform-dev`.
1. Deploy that terraform configuration to the environment that you're using,
   e.g. `govuk-knowledge-graph-dev`.
1. Iterate until you're ready to submit a pull request.
1. Copy the terraform files that you have changed into the other environments,
   e.g. `terraform` and `terraform-staging`.
1. Check that each of the environments is the same by navigating to the root of
   the repository and running the bash script `diff-terraform.sh`.
  The file `diff-exclude` lists which files are permitted to differ between
  environments.
1. Submit a pull request.
1. A GitHub action called `diff-terraform` will do the same checks.
1. After merging the pull request, deploy the terraform to the production
   environment.
1. Optionally deploy the terraform to the other non-production environments,
   after checking that nobody is currently using them.

This workflow ensures that the non-production environments are "eventually
consistent" with the production environment.

### Why not have a single `terraform` folder for all environments?

This would avoid repetition.  If you know a way to achieve this that can cope
with the environments having certain unavoidable differences (project numbers,
feature flags), then please suggest it.

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
