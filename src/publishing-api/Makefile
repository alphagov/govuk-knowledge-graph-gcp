SHELL := /bin/bash

# Parallelise with all cores, if possible
NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
MAKEFLAGS += -j$(NPROCS)

# Names of tables in the postgres database to export to Cloud Storage
# and BigQuery
EXPORT = actions change_notes documents editions events expanded_links link_changes link_sets links path_reservations unpublishings

# A step to create all the targets described in the CSV.GZ and BIGQUERY
# variables, which means that all the .sh and .sql scripts in the SH and
# BIGQUERY variables will be executed.
.PHONY: all
all: $(EXPORT)

actions:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

change_notes:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

documents:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

# This task takes longer than all the others put together, so there's no point
# running with more than two cores.
editions:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

events:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

expanded_links:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

link_changes:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

link_sets:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

links:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

path_reservations:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

unpublishings:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@
