SHELL := /bin/bash

# Parallelise with all cores, if possible
NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
MAKEFLAGS += -j$(NPROCS)

# Get the names of all the shell scripts in the cypher/ directory.  Each of these
# scripts loads data into Neo4j
CYPHER = $(wildcard cypher/*.cypher)
TARGET = $(patsubst cypher/%.cypher, %, $(CYPHER))

# A step to create all the targets described in the CYPHER variable
.PHONY: all
all: $(TARGET)

# A step to print the names of all the targets that were derived from the names
# of .cypher scripts.  This is for debugging only.
check:
	@echo "TARGET = $(TARGET)"

# Load the URLs as nodes.  The query doesn't create a file, but Make will know
# to run this before any dependencies
.PHONY: url
url:
	cypher-shell --file cypher/url.cypher

.PHONY: parts
parts:
	cypher-shell --file cypher/parts.cypher

# Once the url data has been loaded, index it
.PHONY: constraint_url
constraint_url: url parts
	cypher-shell --file cypher/constraint_url.cypher

# Once the url data has been loaded and indexed, load something that depends on
# it.
.PHONY: document_type
document_type: constraint_url
	cypher-shell --file cypher/document_type.cypher

.PHONY: phase
phase: constraint_url
	cypher-shell --file cypher/phase.cypher

.PHONY: content_id
content_id: constraint_url
	cypher-shell --file cypher/content_id.cypher

.PHONY: analytics_identifier
analytics_identifier: constraint_url
	cypher-shell --file cypher/analytics_identifier.cypher

.PHONY: acronym
acronym: constraint_url
	cypher-shell --file cypher/acronym.cypher

.PHONY: locale
locale: constraint_url
	cypher-shell --file cypher/locale.cypher

.PHONY: publishing_app
publishing_app: constraint_url
	cypher-shell --file cypher/publishing_app.cypher

.PHONY: updated_at
updated_at: constraint_url
	cypher-shell --file cypher/updated_at.cypher

.PHONY: public_updated_at
public_updated_at: constraint_url
	cypher-shell --file cypher/public_updated_at.cypher

.PHONY: first_published_at
first_published_at: constraint_url
	cypher-shell --file cypher/first_published_at.cypher

.PHONY: withdrawn_at
withdrawn_at: constraint_url
	cypher-shell --file cypher/withdrawn_at.cypher

.PHONY: withdrawn_explanation
withdrawn_explanation: constraint_url
	cypher-shell --file cypher/withdrawn_explanation.cypher

.PHONY: title
title: constraint_url
	cypher-shell --file cypher/title.cypher

.PHONY: description
description: constraint_url
	cypher-shell --file cypher/description.cypher

.PHONY: department_analytics_profile
department_analytics_profile: constraint_url
	cypher-shell --file cypher/department_analytics_profile.cypher

.PHONY: body
body: constraint_url
	cypher-shell --file cypher/body.cypher

.PHONY: body_embedded_links
body_embedded_links: constraint_url
	cypher-shell --file cypher/body_embedded_links.cypher

.PHONY: transaction_start_link
transaction_start_link: constraint_url
	cypher-shell --file cypher/transaction_start_link.cypher

.PHONY: start_button_text
start_button_text: constraint_url
	cypher-shell --file cypher/start_button_text.cypher

.PHONY: has_chapter
has_chapter: constraint_url
	cypher-shell --file cypher/has_chapter.cypher

.PHONY: redirects_to
redirects_to: constraint_url
	cypher-shell --file cypher/redirects_to.cypher

.PHONY: has_homepage_organisation
has_homepage_organisation: constraint_url
	cypher-shell --file cypher/has_homepage_organisation.cypher

.PHONY: has_homepage_person
has_homepage_person: constraint_url
	cypher-shell --file cypher/has_homepage_person.cypher

.PHONY: has_homepage_taxon
has_homepage_taxon: constraint_url
	cypher-shell --file cypher/has_homepage_taxon.cypher

.PHONY: links_to
links_to: constraint_url
	cypher-shell --file cypher/links_to.cypher

.PHONY: self_links
self_links: links_to
	cypher-shell --file cypher/self_links.cypher

.PHONY: suggested_ordered_related_items
suggested_ordered_related_items: links_to
	cypher-shell --file cypher/suggested_ordered_related_items.cypher

.PHONY: ordered_related_items
ordered_related_items: links_to
	cypher-shell --file cypher/ordered_related_items.cypher

.PHONY: ordered_related_items_overrides
ordered_related_items_overrides: links_to
	cypher-shell --file cypher/ordered_related_items_overrides.cypher

.PHONY: has_suggested_ordered_related_items
has_suggested_ordered_related_items: links_to
	cypher-shell --file cypher/has_suggested_ordered_related_items.cypher

.PHONY: has_organisation
has_organisation: links_to
	cypher-shell --file cypher/has_organisation.cypher

.PHONY: has_child_organisation
has_child_organisation: links_to
	cypher-shell --file cypher/has_child_organisation.cypher

.PHONY: has_parent_organisation
has_parent_organisation: links_to
	cypher-shell --file cypher/has_parent_organisation.cypher

.PHONY: has_primary_publishing_organisation
has_primary_publishing_organisation: links_to
	cypher-shell --file cypher/has_primary_publishing_organisation.cypher

.PHONY: has_original_primary_publishing_organisation
has_original_primary_publishing_organisation: links_to
	cypher-shell --file cypher/has_original_primary_publishing_organisation.cypher

.PHONY: has_supporting_organisation
has_supporting_organisation: links_to
	cypher-shell --file cypher/has_supporting_organisation.cypher

.PHONY: has_superseded
has_superseded: links_to
	cypher-shell --file cypher/has_superseded.cypher

.PHONY: is_tagged_to
is_tagged_to: links_to
	cypher-shell --file cypher/is_tagged_to.cypher

.PHONY: has_child
has_child: links_to
	cypher-shell --file cypher/has_child.cypher

.PHONY: has_parent
has_parent: has_homepage_taxon
	cypher-shell --file cypher/has_parent.cypher

.PHONY: external_page
external_page: constraint_url
	cypher-shell --file cypher/external_page.cypher

.PHONY: user_movement
user_movement: constraint_url
	cypher-shell --file cypher/user_movement.cypher

.PHONY: bank_holidays
bank_holidays: constraint_url
	cypher-shell --file cypher/bank_holidays.cypher

.PHONY: page_rank
page_rank: user_movement
	cypher-shell --file cypher/page_rank.cypher
