SHELL := /bin/bash

# Parallelise with all cores, if possible
NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
MAKEFLAGS += -j$(NPROCS)

.PHONY: clean
clean:
	rm data/*
	source ./environments/publishing.env; \
		psql \
			--csv \
			--command="DROP TABLE IF EXISTS editions_latest;" \

export_all_urls: \
	data/all-urls-publishing.csv \
	data/all-urls-content-mongo.csv \
	data/all-urls-content-postgres.csv

.PHONY: restore_all
restore_all:  restore_postgres restore_content_postgres restore_content_mongo ;

.PHONY: docker_up
docker_up:
	docker compose up --detach
	sleep 5 # allow time for the databases to become ready for connections

.PHONY: docker_down
docker_down:
	docker compose down --volumes
	sudo rm -rf databases/*

.PHONY: docker_stop
docker_stop:
	docker-compose stop

.PHONY: restore_postgres
restore_postgres: docker_up
	echo $$(date) Starting to restore the publishing database backup file
	source ./environments/publishing.env; \
		pg_restore \
			--verbose \
			--create \
			--clean \
			--no-owner \
			--jobs=2 \
			--dbname postgres \
			--port=$$PGPORT \
			./backups/publishing-api-postgres_2023-10-05T05_00_01-publishing_api_production.gz
	echo $$(date) Finished restoring the publishing database backup file

.PHONY: restore_content_postgres
restore_content_postgres: docker_up
	echo $$(date) Starting to restore the publishing database backup file
	source ./environments/content-postgres.env; \
		pg_restore \
			--verbose \
			--create \
			--clean \
			--no-owner \
			--jobs=2 \
			--dbname postgres \
			--port=$$PGPORT \
			./backups/2023-10-05T000705Z-content_store_test_deleteme.gz
	echo $$(date) Finished restoring the publishing database backup file

.PHONY: restore_content_mongo
restore_content_mongo: docker_up
	echo $$(date) Starting to restore the content mongo database backup file
	source ./environments/content-mongo.env; \
		tar xzvO  \
			-f ./backups/mongo-api_2023-10-05T00_16_01-content_store_production.gz \
			content_store_production/content_items.bson \
		| mongorestore -v --db=content_store --collection=content_items -
	echo $$(date) Finished restoring the content mongo database backup file

data/all-urls-publishing.csv:
	source ./environments/publishing.env; \
		psql \
			--file=queries/latest-edition-publishing.sql
	source ./environments/publishing.env; \
		psql \
			--csv \
			--command="SELECT content_id,locale,base_path FROM editions_latest;" \
	  > $@

data/all-urls-content-mongo.csv:
	source ./environments/content-mongo.env; \
		mongoexport \
			--quiet \
			--db=content_store \
			--type=csv \
			--collection=content_items \
			--fields=content_id,locale,_id \
		> $@

data/all-urls-content-postgres.csv:
	source ./environments/content-postgres.env; \
		psql \
			--csv \
			--command="SELECT content_id,locale,base_path from content_items;" \
		> $@

# Register which URLs (base paths) are present in each database
data/register-of-all-urls.csv: \
	data/all-urls-publishing.csv \
	data/all-urls-content-mongo.csv \
	data/all-urls-content-postgres.csv
	duckdb databases/duckdb < queries/create-register-of-all-urls.sql

# Register which URLs (base paths) are present in each database
# when they have null content_id
data/register-of-null-content-ids.csv: data/register-of-all-urls.csv
	duckdb databases/duckdb < queries/create-register-of-null-content-ids.sql
