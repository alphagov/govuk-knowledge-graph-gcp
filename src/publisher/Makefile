SHELL := /bin/bash

# Parallelise with all cores, if possible
NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
MAKEFLAGS += -j$(NPROCS)

MONGO_DATABASE=govuk_content_production
BQ_DATASET=publisher

# Names of tables in the Mongo database to export to Cloud Storage
# and BigQuery
EXPORT = editions actions

# A step to create all the targets described in the CSV.GZ and BIGQUERY
# variables, which means that all the .sh and .sql scripts in the SH and
# BIGQUERY variables will be executed.
.PHONY: all
all: $(EXPORT)

editions:
	source functions.sh; export_query_to_bigquery "${MONGO_DATABASE}" "${PROJECT_ID}" "${BQ_DATASET}" "editions" "url,updated_at,version_number,state,major_change,type"

actions:
	source functions.sh; export_query_to_bigquery "${MONGO_DATABASE}" "${PROJECT_ID}" "${BQ_DATASET}" "actions" "url,version_number,action_created_at,action_request_type"
