FROM neo4j:4.4.8-community

# Generate certificates needed for HTTPS/BOLT connections"
ADD neo4j.conf /var/lib/neo4j/conf

# Install gcloud
RUN apt-get update -y
RUN apt-get install -y apt-transport-https ca-certificates gnupg curl
RUN \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && apt-get update -y \
  && apt-get install google-cloud-cli -y \
  # Clean up
  && rm -rf /var/lib/apt/lists/*

RUN \
  # Install utilities
  apt-get update \
  && apt-get install -y \
    curl \
    unzip \
    certbot \
    python3-certbot-nginx \
  # Install the Graph Data Science plugin \
  # https://neo4j.com/docs/graph-data-science/current/installation/neo4j-server/ \
  && cd /tmp \
  && curl -O https://graphdatascience.ninja/neo4j-graph-data-science-2.1.5.zip \
  && unzip neo4j-graph-data-science-2.1.5.zip neo4j-graph-data-science-2.1.5.jar \
  && mv neo4j-graph-data-science-2.1.5.jar /var/lib/neo4j/plugins \
  && rm neo4j-graph-data-science-2.1.5.zip \
  # Clean up
  && apt-get -y purge --auto-remove \
    curl \
    unzip \
  && rm -rf /var/lib/apt/lists/*

ARG GITHUB_SHA=missing
ENV GITHUB_SHA=${GITHUB_SHA}

ARG GITHUB_REF=missing
ENV GITHUB_REF=${GITHUB_REF}

# Use a modified entrypoint script that doesn't run CMD as the neo4j user, but
# as root, so that certbot will work.
COPY ./docker-entrypoint.sh /startup/

ENV PROJECT_ID govuk-knowledge-graph-staging

# Run a script from a copy of the HEAD of the repository
CMD \
  gcloud storage cat "gs://${PROJECT_ID}-repository/docker/neo4j/run.sh" \
  | bash
