# Virtual machine to import Publishing API data into BigQuery

The Publishing API database is backed up daily to files in AWS S3, which are copied into a GCP bucket by the [`govuk-s3-mirror`][govuk-s3-mirror].

This VM runs scripts that fetch the backup file, extract each table as plain text, and upload them into BigQuery tables.  It runs on a PostgreSQL image that is isued only for the `pg_restore` command.  There is no need to restore the backup to an actual running database.

## Build the image

This folder only contains the `Dockerfile` and `entrypoint.sh`. A GitHub action rebuilds the image when these files are changed, and pushes it to the Artifact Registry.

The rest of the code is in [`src/publishing-api`][src].  When the VM starts, the `entrypoint.sh` script fetches that code and runs it.  This separation avoids having to rebuild the docker image when only changing the code that it runs.

## Trigger the VM to start

When the [govuk-s3-mirror][govuk-s3-mirror] finishes copying any file into its GCP bucket, it publishes a message to Pub/Sub channel.  This project subscribes to that channel. A [workflow][workflow] reads the messages, and if they describe a file whose name fits the pattern for Publishing API database backups, then it starts an instance of this virtual machine.

### Manually start the VM

Open a recent, successful [workflow-run][workflow-runs].  Its state will be `return_started_publishing_api: Succeeded`.  Click "Execute again" and then "Execute".  This will run the workflow with the last input, which was a message that carried the information that the VM needs to find the Publishing API database backup file.

If the most recent successful workflow run was a few days ago, then the Publishing API database backup file that it responded to might have been deleted.  In this case, make a new copy of any of the Publishing API database backup files that do exist in the [bucket][bucket].  Doing so will create a new message in Pub/Sub, which will soon trigger the workflow to start the VM.

[govuk-s3-mirror]: https://github.com/alphagov/govuk-s3-mirror
[bucket]: https://console.cloud.google.com/storage/browser/govuk-s3-mirror_govuk-database-backups/publishing-api-postgres
[workflow-terraform]: ../../terraform/workflows/govuk-database-backups.yaml
[workflow-runs]: https://console.cloud.google.com/workflows/workflow/europe-west2/govuk-database-backups/executions?project=govuk-knowledge-graph&pli=1
[src]: ../../src/publishing-api
[github-action]: ../../.github/workflows/docker-publishing-api.yml
