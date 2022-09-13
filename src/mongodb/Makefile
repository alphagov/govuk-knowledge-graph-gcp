SHELL := /bin/bash

# Parallelise with all cores, if possible
NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
MAKEFLAGS += -j$(NPROCS)

SH = $(wildcard sh/*.sh)
CSV.GZ = $(patsubst sh/%.sh, data/%.csv.gz, $(SH))

.PHONY: all
all: $(CSV.GZ)

check:
	@echo "CSV.GZ = $(CSV.GZ)"

.PHONY: clean
clean: clean.mongodb clean.gz

.PHONY: clean.mongodb
clean.mongodb:
	rm temp/*

.PHONY: clean.gz
clean.gz:
	rm data/*

temp/index.mongodb:
	mongo content_store js/index.js
	touch temp/index.mongodb

# Prepend https://gov.uk to every _id to create a complete URL.
# This doesn't affect any partial URLs elsewhere in the documents.
temp/define_url.mongodb: temp/index.mongodb
	mongo content_store js/define_url.js
	touch temp/define_url.mongodb

data/url.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/url.sh

data/phase.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/phase.sh

data/content_id.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/content_id.sh

data/analytics_identifier.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/analytics_identifier.sh

data/acronym.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/acronym.sh

data/parts.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/parts.sh

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

data/withdrawn_explanation.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/withdrawn_explanation.sh

temp/title.mongodb: temp/define_url.mongodb
	mongo content_store js/title.js
	touch temp/title.mongodb

data/title.csv.gz: temp/title.mongodb
	source functions.sh; source sh/title.sh

temp/description.mongodb: temp/define_url.mongodb
	mongo content_store js/description.js
	touch temp/description.mongodb

data/description.csv.gz: temp/description.mongodb
	source functions.sh; source sh/description.sh

temp/step_by_step_content.mongodb: temp/define_url.mongodb
	mongo content_store js/step_by_step_content.js
	touch temp/step_by_step_content.mongodb

data/step_by_step_content.csv.gz: temp/step_by_step_content.mongodb
	source functions.sh; source sh/step_by_step_content.sh

data/step_by_step_lines.csv.gz: temp/step_by_step_content.mongodb
	source functions.sh; source sh/step_by_step_lines.sh

data/step_by_step_embedded_links.csv.gz: temp/step_by_step_content.mongodb
	source functions.sh; source sh/step_by_step_embedded_links.sh

data/department_analytics_profile.csv.gz: temp/define_url.mongodb
	source functions.sh; source sh/department_analytics_profile.sh

temp/transaction_start_link.mongodb: temp/define_url.mongodb
	mongo content_store js/transaction_start_link.js
	touch temp/transaction_start_link.mongodb

data/transaction_start_link.csv.gz: temp/transaction_start_link.mongodb
	source functions.sh; source sh/transaction_start_link.sh

data/start_button_text.csv.gz: temp/define_url.mongodb
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

data/parts_content.csv.gz: temp/parts_content.mongodb
	source functions.sh; source sh/parts_content.sh

data/parts_lines.csv.gz: temp/parts_content.mongodb
	source functions.sh; source sh/parts_lines.sh

data/parts_embedded_links.csv.gz: temp/parts_content.mongodb
	source functions.sh; source sh/parts_embedded_links.sh

temp/transaction_content.mongodb: temp/define_url.mongodb
	mongo content_store js/transaction_content.js
	touch temp/transaction_content.mongodb

data/transaction_content.csv.gz: temp/transaction_content.mongodb
	source functions.sh; source sh/transaction_content.sh

data/transaction_lines.csv.gz: temp/transaction_content.mongodb
	source functions.sh; source sh/transaction_lines.sh

data/transaction_embedded_links.csv.gz: temp/transaction_content.mongodb
	source functions.sh; source sh/transaction_embedded_links.sh

temp/place_content.mongodb: temp/define_url.mongodb
	mongo content_store js/place_content.js
	touch temp/place_content.mongodb

data/place_content.csv.gz: temp/place_content.mongodb
	source functions.sh; source sh/place_content.sh

data/place_lines.csv.gz: temp/place_content.mongodb
	source functions.sh; source sh/place_lines.sh

data/place_embedded_links.csv.gz: temp/place_content.mongodb
	source functions.sh; source sh/place_embedded_links.sh

# Some document types have the body text in the 'body' field (not 'body.content')
temp/body.mongodb: temp/define_url.mongodb
	mongo content_store js/body.js
	touch temp/body.mongodb

data/body.csv.gz: temp/body.mongodb
	source functions.sh; source sh/body.sh

data/body_lines.csv.gz: temp/body.mongodb
	source functions.sh; source sh/body_lines.sh

data/body_embedded_links.csv.gz: temp/body.mongodb
	source functions.sh; source sh/body_embedded_links.sh

# Some document types have the body text in the 'body.content' field (not 'body')
temp/body_content.mongodb: temp/define_url.mongodb
	mongo content_store js/body_content.js
	touch temp/body_content.mongodb

data/body_content.csv.gz: temp/body_content.mongodb
	source functions.sh; source sh/body_content.sh

data/body_content_lines.csv.gz: temp/body_content.mongodb
	source functions.sh; source sh/body_content_lines.sh

data/body_content_embedded_links.csv.gz: temp/body_content.mongodb
	source functions.sh; source sh/body_content_embedded_links.sh

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
