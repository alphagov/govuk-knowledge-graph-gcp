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
CSV.GZ = $(patsubst sh/%.sh, data/role_%.csv.gz, $(SH))

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
# of .sh scripts.  This is for debugging only.
check:
	@echo "CSV.GZ:"
	@echo "${CSV.GZ}" | tr -s ' ' '\n'
	@echo -e "\nBIGQUERY:"
	@echo "${BIGQUERY}" | tr -s ' ' '\n'

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

# Create a table of all roles (with relevant columns) that are live in the
# content store, even if they are redirects or withdrawn.
temp/roles.postgres:
	psql \
		--username=postgres \
		--dbname=publishing_api_production \
    --file=sql/roles.sql
	touch $@

# Download the url field of every role
data/role_role_url.csv.gz: temp/roles.postgres
	source functions.sh; source sh/role_url.sh
	touch $@

data/role_document_type.csv.gz: temp/roles.postgres
	source functions.sh; source sh/document_type.sh
	touch $@

data/role_publishing_app.csv.gz: temp/roles.postgres
	source functions.sh; source sh/publishing_app.sh
	touch $@

data/role_phase.csv.gz: temp/roles.postgres
	source functions.sh; source sh/phase.sh
	touch $@

data/role_content_id.csv.gz: temp/roles.postgres
	source functions.sh; source sh/content_id.sh
	touch $@

data/role_locale.csv.gz: temp/roles.postgres
	source functions.sh; source sh/locale.sh
	touch $@

data/role_updated_at.csv.gz: temp/roles.postgres
	source functions.sh; source sh/updated_at.sh
	touch $@

data/role_public_updated_at.csv.gz: temp/roles.postgres
	source functions.sh; source sh/public_updated_at.sh
	touch $@

data/role_first_published_at.csv.gz: temp/roles.postgres
	source functions.sh; source sh/first_published_at.sh
	touch $@

data/role_homepage_url.csv.gz: temp/roles.postgres
	source functions.sh; source sh/homepage_url.sh
	touch $@

data/role_title.csv.gz: temp/roles.postgres
	source functions.sh; source sh/title.sh
	touch $@

data/role_description.csv.gz: temp/roles.postgres
	source functions.sh; source sh/description.sh
	touch $@

data/role_attends_cabinet_type.csv.gz: temp/roles.postgres
	source functions.sh; source sh/attends_cabinet_type.sh

data/role_role_payment_type.csv.gz: temp/roles.postgres
	source functions.sh; source sh/role_payment_type.sh

data/role_seniority.csv.gz: temp/roles.postgres
	source functions.sh; source sh/seniority.sh

data/role_whip_organisation.csv.gz: temp/roles.postgres
	source functions.sh; source sh/whip_organisation.sh

data/role_content.csv.gz: temp/roles.postgres
	source functions.sh; source sh/content.sh
	touch $@

data/role_content_text.csv.gz: data/role_content.csv.gz
	source functions.sh; source sh/content_text.sh

data/role_embedded_links.csv.gz: data/role_content.csv.gz
	source functions.sh; source sh/embedded_links.sh

data/role_redirects.csv.gz:
	source functions.sh; source sh/redirects.sh

# Create a table of all current and historic role appointments.
temp/appointments.postgres:
	psql \
		--username=postgres \
		--dbname=publishing_api_production \
    --file=sql/appointments.sql
	touch $@

# Download the url field of every role_appointment
data/role_appointment_url.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_url.sh
	touch $@

# Download metadata about each role_appointment
data/role_appointment_current.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_current.sh
	touch $@

data/role_appointment_started_on.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_started_on.sh
	touch $@

data/role_appointment_ended_on.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_ended_on.sh
	touch $@

# Download links between appointments and roles
data/role_appointment_role.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_role.sh
	touch $@

# Download links between appointments and people
data/role_appointment_person.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_person.sh
	touch $@

# Download links between roles and organisations
data/role_role_organisation.csv.gz: temp/roles.postgres
	source functions.sh; source sh/role_organisation.sh
	touch $@

temp/role.bigquery: \
data/role_role_url.csv.gz \
data/role_document_type.csv.gz \
data/role_phase.csv.gz \
data/role_content_id.csv.gz \
data/role_locale.csv.gz \
data/role_publishing_app.csv.gz \
data/role_updated_at.csv.gz \
data/role_public_updated_at.csv.gz \
data/role_first_published_at.csv.gz \
data/role_title.csv.gz \
data/role_description.csv.gz \
data/role_content.csv.gz
	source functions.sh; query_bigquery file_name=bigquery/role.sql
	touch $@

temp/has_homepage.bigquery: data/role_homepage_url.csv.gz
	source functions.sh; query_bigquery file_name=bigquery/has_homepage.sql

temp/has_role.bigquery: \
data/role_appointment_url.csv.gz \
data/role_appointment_current.csv.gz \
data/role_appointment_started_on.csv.gz \
data/role_appointment_ended_on.csv.gz \
data/role_appointment_person.csv.gz \
data/role_appointment_role.csv.gz
	source functions.sh; query_bigquery file_name=bigquery/has_role.sql

temp/belongs_to.bigquery: data/role_role_organisation.csv.gz
	source functions.sh; query_bigquery file_name=bigquery/belongs_to.sql
