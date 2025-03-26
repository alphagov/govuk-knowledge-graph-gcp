# Import Whitehall data into BigQuery

The Whitehall database is backed up daily to files in AWS S3, which are copied into a GCP bucket by the [govuk-s3-mirror][govuk-s3-mirror].

A virtual machine fetches the scripts in this directory from the copy of the HEAD of this repository that is synced to a [bucket][bucket], and runs [`run.sh`][run.sh], which initiates the following steps.

1. Fetch the Whitehall database backup file. It knows where to find it from environment variables that are set when the [workflow][workflow-terraform] starts the virtual machine ([more details][docker]).
2. Start a MariaDB server and wait for it to come online.
3. Create a Whitehall database to restore the data to.
4. Import the data into MariaDB.
5. Export the selected tables into CSV files.
6. Upload the data into BigQuery.

A Makefile is used to parallelise the tasks.

## Dockerfile

The [Docker configuration][docker] is separate, so that changes to the code here don't cause the image to be rebuilt unnecessarily.  When the virtual machine starts, it fetches [`run.sh`][run.sh] from the copy of the HEAD of this repository that is synced to a [bucket][bucket].

## Test locally

Local testing is difficult, because the Whitehall database is huge. It can be easier to do the following:

1. Add a line to [`run.sh`][run.sh] `tail -f /dev/null` before the command that deletes the virtual machine.
2. Upload your modified copy of [`run.sh`][run.sh].
3. [Manually start the VM][docker-readme].
4. SSH into the VM.

### SSH into a VM

Once a VM instance is running, you can SSH into it from your local device, in the terminal.

```sh
# SSH into the instance
gcloud compute ssh \
  --zone "europe-west2-b" \
  "whitehall" \
  --project "govuk-knowledge-graph" \
  --tunnel-through-iap

# Wait a while for the docker image to start (about 30 seconds to a minute)

# Get the ID of the docker image.  For example, `klt--ulug`.
docker ps

# Tail the logs of the docker image
docker logs -tf klt--ulug

# Otherwise, SSH directly from your device into the docker image
gcloud compute ssh --zone "europe-west2-b" "whitehall" --project "govuk-knowledge-graph" -- container "klt--ulug" --tunnel-through-iap
```

[bucket]: https://console.cloud.google.com/storage/browser/govuk-knowledge-graph-repository
[docker]: ../../docker/whitehall
[docker-readme]: ../../docker/whitehall/README.md
[run.sh]: ./run.sh
[workflow-terraform]: ../../terraform/workflows/govuk-database-backups.yaml
[govuk-s3-mirror]: https://github.com/alphagov/govuk-s3-mirror