# Virtual machine to import Publisher app data into BigQuery

The Publisher app is used to compose most "mainstream" GOV.UK content.  Its database is backed up daily to files in AWS S3, which are copied into a GCP bucket by the [`govuk-s3-mirror`][govuk-s3-mirror].

A virtual machine fetches the scripts in this directory from the copy of the HEAD of this repository that is synced to a [bucket][bucket], and runs [`run.sh`][run.sh], which initiates the following steps.

1. Fetch the database backup file.  It knows where to find it from environment variables that are set when the [workflow][workflow-terraform] starts the virtual machine ([more details][docker]).
2. Use `mongorestore` to import the backup into a running MongoDB database.
3. Export the results of a query to plain text.
4. Upload the plain text file to a bucket, and thence to BigQuery.  This step could be refactored to upload the data directly to BigQuery.  It was done this way for consistency with other, similar data pipelines that did so to make the data easily available in bulk, because it's very difficult to export large amounts of data from BigQuery. There is no longer a need for bulk data outside of BigQuery.
5. Append the plain text data to a table in BigQuery.  By truncating/appending, BigQuery retains the schema of the table.

## Build the image

This folder only contains the `Dockerfile` and `entrypoint.sh`. A GitHub action rebuilds the image when these files are changed, and pushes it to the Artifact Registry.

The rest of the code is in [`src/publisher`][src].  When the VM starts, the `entrypoint.sh` script fetches that code and runs it.  This separation avoids having to rebuild the docker image when only changing the code that it runs.

## Trigger the VM to start

When the [govuk-s3-mirror][govuk-s3-mirror] finishes copying any file into its GCP bucket, it publishes a message to Pub/Sub channel.  This project subscribes to that channel. A [workflow][workflow] reads the messages, and if they describe a file whose name fits the pattern for Publisher database backups, then it starts an instance of this virtual machine.

### Manually start the VM

Open a recent, successful [workflow-run][workflow-runs].  Its state will be `return_started_publisher: Succeeded`.  Click "Execute again" and then "Execute".  This will run the workflow with the last input, which was a message that carried the information that the VM needs to find the Publisher database backup file.

If the most recent successful workflow run was a few days ago, then the Publisher database backup file that it responded to might have been deleted.  In this case, make a new copy of any of the Publisher database backup files that do exist in the [bucket][bucket].  Doing so will create a new message in Pub/Sub, which will soon trigger the workflow to start the VM.

[govuk-s3-mirror]: https://github.com/alphagov/govuk-s3-mirror
[bucket]: https://console.cloud.google.com/storage/browser/govuk-s3-mirror_govuk-database-backups/publisher
[workflow-terraform]: ../../terraform/workflows/govuk-database-backups.yaml
[workflow-runs]: https://console.cloud.google.com/workflows/workflow/europe-west2/govuk-database-backups/executions?project=govuk-knowledge-graph&pli=1
[src]: ../../src/publisher
[github-action]: ../../.github/workflows/docker-publisher.yml
