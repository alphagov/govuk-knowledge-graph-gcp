# Database comparison

A comparison between three databases that contain GOV.UK content.

- `publishing` is the Publishing API database, which is in PostgreSQL
- `content_mongo` is the current Content Store, which is in MongoDB
- `content_postgres` will replace the current Content Store, and is in PostgreSQL

# Prerequisites

1. Obtain the [backup files](#backup-files)
1. Install `docker` and `docker compose`
1. Install `duckdb`

# Running

`make restore_all` creates a container for each database, and restores data into
them from the backup files.

# Backup files

A backup file is required for each database.  Put them in the `backups` folder.
Their filenames are currently hardcoded in the `Makefile`.

- `backups/publishing-api-postgres_2023-10-05T05_00_01-publishing_api_production.gz` is from the [GOV.UK S3 mirror](https://github.com/alphagov/govuk-s3-mirror).  Backups are only available for recent days.
- `backups/mongo-api_2023-10-05T00_16_01-content_store_production.gz` is from the [GOV.UK S3 mirror](https://github.com/alphagov/govuk-s3-mirror).  Backups are only available for recent days.
- `backups/2023-10-05T000705Z-content_store_test_deleteme.gz` was provided ad
  hoc by the `#govuk-publishing-platform` team.  Daily backup files will be
  available soon.

# Works in progress

- `scripts`
- `queries`

# TODO

- [x] Restore each database from its backup file
- [ ] Export a distinct set of URLs from each database to a CSV file
- [ ] Table which URLs are present in which databases
- [ ] Infer the criteria that determine which URLs are sent from the Publishing
  API database to the Content Store.  Expect some discrepancies.
- [ ] Write part of the knowledge graph data pipeline using:
  - [ ] DBT and the `content_postgres` database
  - [ ] DBT and the `publishing` database
  - [ ] Dataform and the `content_postgres` database
  - [ ] Dataform and the `publishing` database
