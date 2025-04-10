# Import Asset Manager data into BigQuery

The Asset Manager service is used to store files and metadata for the publishing apps. Its database is backed up daily to files in AWS S3, which are copied into a GCP bucket by the [govuk-s3-mirror][govuk-s3-mirror].

A virtual machine fetches the scripts in this directory from the copy of the HEAD of this repository that is synced to a [bucket][bucket], and runs [`run.sh`][run.sh], which initiates the following steps.

1. Fetch the database backup file. It knows where to find it from environment variables that are set when the [workflow][workflow-terraform] starts the virtual machine ([more details][docker]).
2. Use `mongorestore` to import the backup into a running MongoDB database.
3. Export the results of a query to plain text.
4. Append the plain text data to a table in BigQuery. By truncating/appending, BigQuery retains the schema of the table.

## Dockerfile

The [Docker configuration][docker] is separate, so that changes to the code here don't cause the image to be rebuilt unnecessarily.  When the virtual machine starts, it fetches [`run.sh`][run.sh] from the copy of the HEAD of this repository that is synced to a [bucket][bucket].

## Testing locally

To test locally:

1. Add a line to [`run.sh`][run.sh] `tail -f /dev/null` before the command that deletes the virtual machine.
2. Upload your modified copy of [run.sh]
3. [Manually start the VM][docker-readme].
4. SSH into the VM.

### SSH into a VM

Once a VM instance is running, you can SSH into it from your local device, in the
terminal.

```sh
# SSH into the instance
gcloud compute ssh \
  --zone "europe-west2-b" \
  "asset-manager" \
  --project "govuk-knowledge-graph" \
  --tunnel-through-iap

# Wait a while for the docker image to start (about 30 seconds to a minute)

# Get the ID of the docker container. For example, `klt--gdxf`.
docker ps

# Tail the logs of the mongodb docker image
docker logs -tf klt--gdxf

# Tail the logs of the postgres docker image
docker logs -tf klt--gdxf

# Otherwise, SSH directly from your device into the docker container
gcloud compute ssh --zone "europe-west2-b" "asset-manager" --project "govuk-knowledge-graph" -- container "klt--gdxf"
```

[govuk-s3-mirror]: https://github.com/alphagov/govuk-s3-mirror
[bucket]: https://console.cloud.google.com/storage/browser/govuk-knowledge-graph-repository
[docker]: ../../docker/asset-manager
[docker-readme]: ../../docker/asset-manager/README.md
[run.sh]: ./run.sh
[workflow-terraform]: ../../terraform/workflows/govuk-database-backups.yaml
