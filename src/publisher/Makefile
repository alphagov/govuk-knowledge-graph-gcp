SHELL := /bin/bash

# Parallelise with all cores, if possible
NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
MAKEFLAGS += -j$(NPROCS)

# Names of tables in the postgres database to export to Cloud Storage
# and BigQuery
EXPORT = actions editions

# A step to create all the targets described in the CSV.GZ and BIGQUERY
# variables, which means that all the .sh and .sql scripts in the SH and
# BIGQUERY variables will be executed.
.PHONY: all
all: $(EXPORT)

actions:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@

editions:
	source functions.sh; export_to_bigquery backup_name=${FILE_PATH} table_name=$@
