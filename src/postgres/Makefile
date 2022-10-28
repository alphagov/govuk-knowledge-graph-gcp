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
# script is uploaded straight to into a bucket.
CSV.GZ = $(patsubst sh/%.sh, data/role_%.csv.gz, $(SH))

# A step to create all the targets described in the CSV.GZ variable, which means
# that all the .sh scripts in the SH variable will be executed.
.PHONY: all
all: $(CSV.GZ)

# A step to print the names of all the targets that were derived from the names
# of .sh scripts.  This is for debugging only.
check:
	@echo "CSV.GZ = $(CSV.GZ)"

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
	touch temp/roles.postgres

# Download the url field of every role
data/role_role_url.csv.gz: temp/roles.postgres
	source functions.sh; source sh/role_url.sh

data/role_document_type.csv.gz: temp/roles.postgres
	source functions.sh; source sh/document_type.sh

data/role_publishing_app.csv.gz: temp/roles.postgres
	source functions.sh; source sh/publishing_app.sh

data/role_phase.csv.gz: temp/roles.postgres
	source functions.sh; source sh/phase.sh

data/role_content_id.csv.gz: temp/roles.postgres
	source functions.sh; source sh/content_id.sh

data/role_locale.csv.gz: temp/roles.postgres
	source functions.sh; source sh/locale.sh

data/role_updated_at.csv.gz: temp/roles.postgres
	source functions.sh; source sh/updated_at.sh

data/role_public_updated_at.csv.gz: temp/roles.postgres
	source functions.sh; source sh/public_updated_at.sh

data/role_first_published_at.csv.gz: temp/roles.postgres
	source functions.sh; source sh/first_published_at.sh

data/role_homepage_url.csv.gz: temp/roles.postgres
	source functions.sh; source sh/homepage_url.sh

data/role_title.csv.gz: temp/roles.postgres
	source functions.sh; source sh/title.sh

data/role_description.csv.gz: temp/roles.postgres
	source functions.sh; source sh/description.sh

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

data/role_content_text.csv.gz: data/role_content.csv.gz
	source functions.sh; source sh/content_text.sh

data/role_content_lines.csv.gz: data/role_content.csv.gz
	source functions.sh; source sh/content_lines.sh

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
	touch temp/appointments.postgres

# Download the url field of every role_appointment
data/role_appointment_url.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_url.sh

# Download metadata about each role_appointment
data/role_appointment_current.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_current.sh

data/role_appointment_started_on.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_started_on.sh

data/role_appointment_ended_on.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_ended_on.sh

# Download links between appointments and roles
data/role_appointment_role.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_role.sh

# Download links between appointments and people
data/role_appointment_person.csv.gz: temp/appointments.postgres
	source functions.sh; source sh/appointment_person.sh

# Download links between roles and organisations
data/role_role_organisation.csv.gz: temp/roles.postgres
	source functions.sh; source sh/role_organisation.sh
