FROM neo4j:4.4.8-community

# Generate certificates needed for HTTPS/BOLT connections"
ADD neo4j.conf /var/lib/neo4j/conf

RUN \
  # Install utilities
  apt-get update \
  && apt-get install -y \
    curl \
    unzip \
  # Generate certificates needed for HTTPS/BOLT connections"
  && mkdir -p /var/lib/neo4j/certificates \
  && cd /var/lib/neo4j/certificates \
  && openssl req  -nodes -new -x509  -keyout private.key -out public.crt -subj \
    "/C=GB/ST=NRW/L=London/O=GDS/OU=DevOps/CN=www.gov.uk/emailAddress=gds-data-science@digital.cabinet-office.gov.uk" \
  # Install the Graph Data Science plugin \
  # https://neo4j.com/docs/graph-data-science/current/installation/neo4j-server/ \
  && cd /tmp \
  && cd /tmp \
  && curl -O https://graphdatascience.ninja/neo4j-graph-data-science-2.1.5.zip \
  && unzip neo4j-graph-data-science-2.1.5.zip neo4j-graph-data-science-2.1.5.jar \
  && mv neo4j-graph-data-science-2.1.5.jar /var/lib/neo4j/plugins \
  # Clean up
  && apt-get -y purge --auto-remove \
    curl \
    unzip \
  && rm -rf /var/lib/apt/lists/*

ARG GITHUB_SHA=missing
ENV GITHUB_SHA=${GITHUB_SHA}

ARG GITHUB_REF=missing
ENV GITHUB_REF=${GITHUB_REF}
