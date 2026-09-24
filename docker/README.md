# Docker images

# [`html-to-text`][html-to-text]

For a BigQuery remote function implemented in Cloud Run.  This isn't currently
used by anything.  It has to be a docker image in Cloud run, rather than merely
source code in Cloud Functions, because it needs certain system dependencies
(pandoc).

# [`publisher`][publisher]

For a virtual machine in GCE (Google Compute Engine).  It extracts data from a
backup of the Publisher app database, and imports it into BigQuery.

# [`publishing-api`][publishing-api]

For a virtual machine in GCE (Google Compute Engine).  It extracts data from a
backup of the Publshing API database, and imports it into BigQuery.

# [`support-api`][support-api]

For a virtual machine in GCE (Google Compute Engine).  It extracts data from a
backup of the support API database, and imports it into BigQuery.

# [`whitehall`][whitehall]

For a virtual machine in GCE (Google Compute Engine). It extracts data from a
backup of the Whitehall app database, and imports it into BigQuery.

# [`asset-manager`][asset-manager]

For a virtual machine in GCE (Google Compute Engine). It extracts data from a
backup of the Asset Manager app database, and imports it into BigQuery.

[html-to-text]: ./html-to-text
[publisher]: ./publisher
[publishing-api]: ./publisher-api
[support-api]: ./support-api
[whitehall]: ./whitehall
[asset-manager]: ./asset-manager
