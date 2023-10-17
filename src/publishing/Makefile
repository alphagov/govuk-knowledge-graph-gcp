
SHELL := /bin/bash

# Parallelise with all cores, if possible
NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
MAKEFLAGS += -j$(NPROCS)

# Get the names of all the shell scripts in the sh/ directory.  Each of these
# scripts creates a CSV file to be uploaded to a bucket.
SH = $(wildcard sh/*.sh)

# Take the names of the shell scripts, and replace the .sh suffix with .csv.gz.
# These new filenames are used as the 'targets' of some steps in this Makefile.
# No .csv.gz files are ever actually created, because the output of each .sh
# script is uploaded straight to into a bucket, but some blank files are created
# to trigger subsequent targets.
CSV.GZ = $(patsubst sh/%.sh, data/%.csv.gz, $(SH))

# A step to create all the targets described in the CSV.GZ variable, which means
# that all the .sh scripts in the SH variable will be executed.
.PHONY: all
all: $(CSV.GZ)

# A step to print the names of all the targets that were derived from the names
# of .sh scripts.  This is for debugging only.
check:
	@echo "CSV.GZ:"
	@echo "${CSV.GZ}" | tr -s ' ' '\n'

# A step to delete any intermediate files that have been created.  This is for
# development only.
.PHONY: clean
clean: clean.postgres clean.gz

# A step to delete any intermediate files that have been created in the temp/
# directory.  This is for development only.
.PHONY: clean.postgres
clean.postgres:
	rm temp/.* temp/*

# A step to delete any intermediate files that have been created in the data/
# directory.  This is for development only.
.PHONY: clean.gz
clean.gz:
	rm data/.* data/*

# Create a table of the current edition of each document.
data/editions_current.csv.gz:
	source functions.sh; source sh/editions_current.sh
	touch $@

editions_current: data/editions_current.csv.gz
	source functions.sh; export_to_bigquery table_name=$@

# Create a table of editions that are being used by the website, either in the
# content store as documents in their own right, or as expanded links, or as
# search results.  Export the table to BigQuery.
data/editions_online.csv.gz: data/editions_current.csv.gz
	source functions.sh; source sh/editions_online.sh
	touch $@
 touch $@

editions_online: data/editions_online.csv.gz
	source functions.sh; export_to_bigquery table_name=$@

# Create a table of links that are being used by the website.
links_online: data/editions_online.csv.gz
	source functions.sh; export_to_bigquery table_name=$@

# Create a table of the govspeak content of parts of 'guide' and 'travel_advice'
# documents, where each part is rendered as a page on its own URL.
data/parts_govspeak.csv.gz: data/editions_current.csv.gz
	source functions.sh; source sh/parts_govspeak.sh
	touch $@
