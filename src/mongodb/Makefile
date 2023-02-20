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

# Get the names of all the sql scripts in the bigquery/ directory.  Each of these
# scripts runs a query in BigQuery.
BIGQUERY.SQL = $(wildcard bigquery/*.sql)

# Take the names of the sql scripts, and replace the .sql suffix with .bigquery.
# These new filenames are used as the 'targets' of some steps in this Makefile.
# No .bigquery files are ever actually created, but some blank files are created
# to trigger subsequent targets.
BIGQUERY = $(patsubst bigquery/%.sql, temp/%.bigquery, $(BIGQUERY.SQL))

# A step to create all the targets described in the CSV.GZ and BIGQUERY
# variables, which means that all the .sh and .sql scripts in the SH and
# BIGQUERY variables will be executed.
.PHONY: all
all: $(CSV.GZ) $(BIGQUERY)

# A step to print the names of all the targets that were derived from the names
# of .sh and .sql scripts.  This is for debugging only.
check:
	@echo "CSV.GZ:"
	@echo "${CSV.GZ}" | tr -s ' ' '\n'
	@echo -e "\nBIGQUERY:"
	@echo "${BIGQUERY}" | tr -s ' ' '\n'

# A step to delete any intermediate files that have been created.  This is for
# development only.
.PHONY: clean
clean: clean.mongodb clean.gz

# A step to delete any intermediate files that have been created in the temp/
# directory.  This is for development only.
.PHONY: clean.mongodb
clean.mongodb:
	rm temp/*

# A step to delete any intermediate files that have been created in the data/
# directory.  This is for development only.
.PHONY: clean.gz
clean.gz:
	rm data/*

# Create an index on the document_type field.  The query doesn't create a file,
# so a dummy target file is created by the `touch` command, so that subsequent
# steps know that this step has been executed.  A similar trick is used in many
# places in this Makefile.
temp/index.mongodb:
	mongo content_store js/index.js
	touch temp/index.mongodb

# Create a url field by prepending https://gov.uk to the value of _id field.
temp/define_url.mongodb:
	mongo content_store js/define_url.js
	touch temp/define_url.mongodb

# Once the url field has been defined, download the url field of every document.
# The file functions.sh is sourced so that the functions that it defines are
# available to the sh/url.sh script.  A similar thing is done in many places in
# this Makefile.
data/url.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/url.sh
	touch data/url.csv.gz

# Each of the following several steps depends on the same prerequisite, so they
# can be executed in parallel.
data/phase.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/phase.sh

data/content_id.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/content_id.sh

data/analytics_identifier.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/analytics_identifier.sh

data/acronym.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/acronym.sh

data/document_type.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/document_type.sh

data/locale.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/locale.sh

data/publishing_app.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/publishing_app.sh

data/updated_at.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/updated_at.sh

data/public_updated_at.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/public_updated_at.sh

data/first_published_at.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/first_published_at.sh

data/withdrawn_at.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/withdrawn_at.sh

# Create a dataset in MongoDB that contains a clean-up version of the title
# field of each document.  The query doesn't create a file, so a dummy target
# file is created by the `touch` command, so that subsequent steps know that
# this step has been executed.  A similar trick is used in many places in this
# Makefile.
temp/title.mongodb: temp/define_url.mongodb
	mongo content_store js/title.js
	touch temp/title.mongodb

# Download a CSV file of the title dataset that was previously created.
data/title.csv.gz: temp/title.mongodb
	source functions.sh; source sh/title.sh

temp/withdrawn_explanation.mongodb: temp/define_url.mongodb
	mongo content_store js/withdrawn_explanation.js
	touch temp/withdrawn_explanation.mongodb

data/withdrawn_explanation.csv.gz: temp/withdrawn_explanation.mongodb
	source functions.sh; source sh/withdrawn_explanation.sh

temp/description.mongodb: temp/define_url.mongodb
	mongo content_store js/description.js
	touch temp/description.mongodb

data/description.csv.gz: temp/description.mongodb
	source functions.sh; source sh/description.sh

temp/step_by_step_content.mongodb: temp/define_url.mongodb  temp/index.mongodb
	mongo content_store js/step_by_step_content.js
	touch temp/step_by_step_content.mongodb

data/step_by_step_content.csv.gz: temp/step_by_step_content.mongodb
	source functions.sh; source sh/step_by_step_content.sh
	touch data/step_by_step_content.csv.gz

data/step_by_step_embedded_links.csv.gz: temp/step_by_step_content.mongodb
	source functions.sh; source sh/step_by_step_embedded_links.sh
	touch data/step_by_step_embedded_links.csv.gz

data/department_analytics_profile.csv.gz: temp/define_url.mongodb temp/index.mongodb
	source functions.sh; source sh/department_analytics_profile.sh

temp/transaction_start_link.mongodb: temp/define_url.mongodb temp/index.mongodb
	mongo content_store js/transaction_start_link.js
	touch temp/transaction_start_link.mongodb

data/transaction_start_link.csv.gz: temp/transaction_start_link.mongodb
	source functions.sh; source sh/transaction_start_link.sh

data/start_button_text.csv.gz: temp/define_url.mongodb temp/index.mongodb
	source functions.sh; source sh/start_button_text.sh

temp/expanded_links.mongodb: temp/define_url.mongodb
	mongo content_store js/expanded_links.js
	touch temp/expanded_links.mongodb

data/expanded_links.csv.gz: temp/expanded_links.mongodb
	source functions.sh; source sh/expanded_links.sh

temp/expanded_links_content_ids.mongodb: temp/define_url.mongodb
	mongo content_store js/expanded_links_content_ids.js
	touch temp/expanded_links_content_ids.mongodb

data/expanded_links_content_ids.csv.gz: temp/expanded_links_content_ids.mongodb
	source functions.sh; source sh/expanded_links_content_ids.sh

temp/parts_content.mongodb: temp/define_url.mongodb
	mongo content_store js/parts_content.js
	touch temp/parts_content.mongodb

data/parts.csv.gz: temp/parts_content.mongodb
	source functions.sh; source sh/parts.sh

data/parts_content.csv.gz: temp/parts_content.mongodb
	source functions.sh; source sh/parts_content.sh
	touch data/parts_content.csv.gz

data/parts_embedded_links.csv.gz: temp/parts_content.mongodb
	source functions.sh; source sh/parts_embedded_links.sh
	touch data/parts_embedded_links.csv.gz

temp/transaction_content.mongodb: temp/define_url.mongodb temp/index.mongodb
	mongo content_store js/transaction_content.js
	touch temp/transaction_content.mongodb

data/transaction_content.csv.gz: temp/transaction_content.mongodb
	source functions.sh; source sh/transaction_content.sh
	touch data/transaction_content.csv.gz

data/transaction_embedded_links.csv.gz: temp/transaction_content.mongodb
	source functions.sh; source sh/transaction_embedded_links.sh
	touch data/transaction_embedded_links.csv.gz

temp/place_content.mongodb: temp/define_url.mongodb temp/index.mongodb
	mongo content_store js/place_content.js
	touch temp/place_content.mongodb

data/place_content.csv.gz: temp/place_content.mongodb
	source functions.sh; source sh/place_content.sh
	touch data/place_content.csv.gz

data/place_embedded_links.csv.gz: temp/place_content.mongodb
	source functions.sh; source sh/place_embedded_links.sh
	touch data/place_embedded_links.csv.gz

# Some document types have the body text in the 'body' field (not 'body.content')
temp/body.mongodb: temp/define_url.mongodb temp/index.mongodb
	mongo content_store js/body.js
	touch temp/body.mongodb

data/body.csv.gz: temp/body.mongodb
	source functions.sh; source sh/body.sh
	touch data/body.csv.gz

data/body_embedded_links.csv.gz: temp/body.mongodb
	source functions.sh; source sh/body_embedded_links.sh
	touch data/body_embedded_links.csv.gz

# Some document types have the body text in the 'body.content' field (not 'body')
temp/body_content.mongodb: temp/define_url.mongodb temp/index.mongodb
	mongo content_store js/body_content.js
	touch temp/body_content.mongodb

data/body_content.csv.gz: temp/body_content.mongodb
	source functions.sh; source sh/body_content.sh
	touch data/body_content.csv.gz

data/body_content_embedded_links.csv.gz: temp/body_content.mongodb
	source functions.sh; source sh/body_content_embedded_links.sh
	touch data/body_content_embedded_links.csv.gz

# Combine the tables of content of each document type, export back into a
# storage bucket as many files, and concatenate those files into a single file.
temp/content.bigquery: data/step_by_step_content.csv.gz data/parts_content.csv.gz data/transaction_content.csv.gz data/place_content.csv.gz data/body.csv.gz data/body_content.csv.gz
	-gcloud storage rm \
		"gs://${PROJECT_ID}-data-processed/bigquery/content_[0-9]*.csv.gz" \
    --continue-on-error
	envsubst < ./bigquery/content.sql \
		| bq query --use_legacy_sql=false \
		< /dev/stdin
	touch temp/content.bigquery

# Derive a table of one row per line of content per page, export back into a
# storage bucket as many files, and concatenate those files into a single file.
temp/lines.bigquery: temp/content.bigquery
	-gcloud storage rm \
		"gs://${PROJECT_ID}-data-processed/bigquery/lines_[0-9]*.csv.gz" \
    --continue-on-error
	envsubst < ./bigquery/lines.sql \
		| bq query --use_legacy_sql=false \
		< /dev/stdin

# Combine the tables of embedded_links of each document type, export back into a
# storage bucket as many files, and concatenate those files into a single file.
temp/embedded_links.bigquery: data/step_by_step_embedded_links.csv.gz data/parts_embedded_links.csv.gz data/transaction_embedded_links.csv.gz data/place_embedded_links.csv.gz data/body_embedded_links.csv.gz data/body_content_embedded_links.csv.gz
	-gcloud storage rm \
		"gs://${PROJECT_ID}-data-processed/bigquery/embedded_links_[0-9]*.csv.gz" \
    --continue-on-error
	envsubst < ./bigquery/embedded_links.sql \
	  | bq query --use_legacy_sql=false \
	  < /dev/stdin
	touch $@

# Redirects of two kinds
temp/url_override.mongodb: temp/define_url.mongodb
	mongo content_store js/url_override.js
	touch temp/url_override.mongodb

data/url_override.csv.gz: temp/url_override.mongodb
	source functions.sh; source sh/url_override.sh

temp/redirects.mongodb: temp/define_url.mongodb
	mongo content_store js/redirects.js
	touch temp/redirects.mongodb

data/redirects.csv.gz: temp/redirects.mongodb
	source functions.sh; source sh/redirects.sh

# Taxon levels
temp/taxon_levels.mongodb: temp/define_url.mongodb temp/index.mongodb
	mongo content_store js/taxon_levels.js
	touch temp/taxon_levels.mongodb

data/taxon_levels.csv.gz: temp/taxon_levels.mongodb
	source functions.sh; source sh/taxon_levels.sh

# Assume that the content.pagerank table has been refreshed by another process
temp/page.bigquery: \
	data/url.csv.gz \
	data/document_type.csv.gz \
	data/phase.csv.gz \
	data/content_id.csv.gz \
	data/analytics_identifier.csv.gz \
	data/acronym.csv.gz \
	data/locale.csv.gz \
	data/publishing_app.csv.gz \
	data/updated_at.csv.gz \
	data/public_updated_at.csv.gz \
	data/first_published_at.csv.gz \
	data/withdrawn_at.csv.gz \
	data/withdrawn_explanation.csv.gz \
	data/title.csv.gz \
	data/description.csv.gz \
	data/department_analytics_profile.csv.gz \
	data/parts.csv.gz \
	temp/content.bigquery \
	temp/is_tagged_to.bigquery \
	temp/taxon_levels.mongodb
	source functions.sh; query_bigquery file_name=bigquery/page.sql
	touch $@

temp/external_page.bigquery: temp/page.bigquery temp/hyperlinks_to.bigquery
	source functions.sh; query_bigquery file_name=bigquery/external_page.sql

temp/has_homepage.bigquery: data/taxon_levels.csv.gz temp/page.bigquery
	source functions.sh; query_bigquery file_name=bigquery/has_homepage.sql
	touch $@

temp/has_child_organisation.bigquery: data/expanded_links.csv.gz temp/has_homepage.bigquery
	source functions.sh; query_bigquery file_name=bigquery/has_child_organisation.sql

temp/has_organisation.bigquery: data/expanded_links.csv.gz temp/has_homepage.bigquery
	source functions.sh; query_bigquery file_name=bigquery/has_organisation.sql

temp/has_parent.bigquery: data/expanded_links.csv.gz temp/has_homepage.bigquery
	source functions.sh; query_bigquery file_name=bigquery/has_parent.sql
	touch $@

temp/has_successor.bigquery: data/expanded_links.csv.gz
	source functions.sh; query_bigquery file_name=bigquery/has_successor.sql
	touch $@

temp/has_primary_publishing_organisation.bigquery: \
	data/expanded_links.csv.gz \
	temp/has_homepage.bigquery
	source functions.sh; query_bigquery file_name=bigquery/has_primary_publishing_organisation.sql

temp/hyperlinks_to.bigquery: \
	temp/embedded_links.bigquery \
	data/expanded_links.csv.gz \
	temp/page.bigquery
	source functions.sh; query_bigquery file_name=bigquery/hyperlinks_to.sql
	touch temp/hyperlinks_to.bigquery

temp/is_tagged_to.bigquery: \
	data/expanded_links.csv.gz
	source functions.sh; query_bigquery file_name=bigquery/is_tagged_to.sql

temp/organisation.bigquery: temp/page.bigquery
	source functions.sh; query_bigquery file_name=bigquery/organisation.sql

temp/person.bigquery: temp/page.bigquery
	source functions.sh; query_bigquery file_name=bigquery/person.sql

temp/taxon.bigquery: \
	data/taxon_levels.csv.gz \
	temp/page.bigquery
	source functions.sh; query_bigquery file_name=bigquery/taxon.sql
	touch $@

temp/taxon_ancestors.bigquery: \
	data/taxon_levels.csv.gz \
	temp/has_parent.bigquery \
	temp/taxon.bigquery
	source functions.sh; query_bigquery file_name=bigquery/taxon_ancestors.sql
