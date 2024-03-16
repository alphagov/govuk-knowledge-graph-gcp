# Import Publishing API data into BigQuery

The Publishing API database is backed up daily to files in AWS S3, which are copied into a GCP bucket by the [`govuk-s3-mirror`][govuk-s3-mirror].

A virtual machine fetches the scripts in this directory from the copy of the HEAD of this repository that is synced to a [bucket][bucket], and runs [`run.sh`][run.sh], which initiates the following steps.

1. Fetch the Publishing API database backup file.  It knows where to find it from environment variables that are set when the [workflow][workflow-terraform] starts the virtual machine ([more details][docker]).
2. Use `pg_restore` to extract each table's data as plain text.  There is no need to actually restore the data to a running PostgreSQL instance.
3. `TRUNCATE` (empty) each table in BigQuery.
4. Append the new data to each table in BigQuery.  By truncating/appending, BigQuery retains the schema of each table.

In March 2024 this took about 65 minutes.  A Makefile is used to parallelise the tasks.  The `editions` table takes longer than all the others put together, so there is no point using a machine with more than two cores.

## Dockerfile

The [Docker configuration][docker] is separate, so that changes to the code here don't cause the image to be rebuilt unnecessarily.  When the virtual machine starts, it fetches [`run.sh`][run.sh] from the copy of the HEAD of this repository that is synced to a [bucket][bucket].

## Test locally

Local testing is difficult, because the Publishing API database is huge.  It can be easier to do the following:

1. Add a line to [`run.sh`][run.sh] `tail -f /dev/null` before the command that deletes the virtual machine.
2. Upload your modified copy of [run.sh].
3. [Manually start the VM][docker-readme].
4. SSH into the VM.

### SSH into a VM

Once a VM instance is running, you can SSH into it from your local device, in the
terminal.

```sh
# SSH into the instance
gcloud compute ssh \
  --zone "europe-west2-b" \
  "publishing-api" \
  --project "govuk-knowledge-graph"

# Wait a while for the docker image to start (about 30 seconds to a minute)

# Get the ID of the docker image.  For example, `klt--ulug`.
docker ps

# Tail the logs of the mongodb docker image
docker logs -tf klt--ulug

# Tail the logs of the postgres docker image
docker logs -tf klt--ulug

# Otherwise, SSH directly from your device into the docker image
gcloud compute ssh --zone "europe-west2-b" "publishing-api" --project "govuk-knowledge-graph" -- container "klt--ulug"
```

[bucket]: https://console.cloud.google.com/storage/browser/govuk-knowledge-graph-repository
[docker]: ../../docker/publishing-api
[docker-readme]: ../../docker/publishing-api/README.md
[run.sh]: ./run.sh
[workflow-terraform]: ../../terraform/workflows/govuk-integration-database-backups.yaml
