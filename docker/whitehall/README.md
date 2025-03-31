# Virtual machine to import Whitehall data into BigQuery

The Whitehall database is backed up daily to files in AWS S3, which are copied into a GCP bucket by the [govuk-s3-mirror][govuk-s3-mirror].

This VM imports a backup from the govuk S3 mirror bucket, restores it to a temporary MariaDB instance and exports it to a CSV file before uploading to BigQuery.

## Build the image

This folder only contains the [`Dockerfile`][Dockerfile] and [`entrypoint.sh`][entrypoint.sh]. A GitHub action rebuilds the image when these files are changed, and pushes it to the Artifact Registry.

The rest of the code is in [`src/whitehall`][src]. When the VM starts, the [`entrypoint.sh`][entrypoint.sh] script fetches that code and runs it. This separation avoids having to rebuild the docker image when only changing the code that it runs.

## Trigger the VM to start

When the [govuk-s3-mirror][govuk-s3-mirror] finishes copying any file into its GCP bucket, it publishes a message to Pub/Sub channel. This project subscribes to that channel. A [workflow][workflow-terraform] reads the messages, and if they describe a file whose name fits the pattern for Whitehall database backups, then it starts an instance of this virtual machine.

### Manually start the VM

Open a recent, successful [workflow-run][workflow-runs]. Its state will be `return_started_whitehall: Succeeded`. Click "Execute again" and then "Execute". This will run the workflow with the last input, which was a message that carried the information that the VM needs to find the Whitehall database backup file.

If the most recent successful workflow run was a few days ago, then the Whitehall database backup file that it responded to might have been deleted. In this case, make a new copy of one of the Whitehall database backup files that do exist in the [bucket][bucket]. Doing so will create a new message in Pub/Sub, which will soon trigger the workflow to start the VM.

## Local build

To build the image locally, decrease the `innodb_buffer_pool_size`, by overriding the values in [my.cnf][./my.cnf].

[govuk-s3-mirror]: https://github.com/alphagov/govuk-s3-mirror
[bucket]: https://console.cloud.google.com/storage/browser/govuk-s3-mirror_govuk-database-backups/whitehall-mysql
[workflow-terraform]: ../../terraform/workflows/govuk-database-backups.yaml
[workflow-runs]: https://console.cloud.google.com/workflows/workflow/europe-west2/govuk-database-backups/executions?project=govuk-knowledge-graph&pli=1
[src]: ../../src/whitehall
[github-action]: ../../.github/workflows/docker-whitehall.yml
[entrypoint.sh]: ./entrypoint.sh
[Dockerfile]: ./Dockerfile
[my.cnf]: ./my.cnf
