SHELL := /bin/bash

# Parallelise with all cores, if possible
NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
MAKEFLAGS += -j$(NPROCS)

# Names of tables in the MySQL database to export to Cloud Storage
# and BigQuery
EXPORT = editions assets attachments attachment_data

# A step to create all the targets described in the CSV.GZ and BIGQUERY
# variables, which means that all the .sh and .sql scripts in the SH and
# BIGQUERY variables will be executed.
.PHONY: all
all: $(EXPORT)

editions:
	source functions.sh; export_editions_to_bigquery

assets:
	source functions.sh; export_assets_to_bigquery

attachments:
	source functions.sh; export_attachments_to_bigquery

attachment_data:
	source functions.sh; export_attachment_data_to_bigquery