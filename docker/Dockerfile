FROM neo4j:4.4.8-community

# Serve the Neo4j browser and API on port 8080
RUN sed -i \
  's/^#dbms\.connector\.http\.listen_address=:7474$/dbms.connector.http.listen_address=:8080/' \
  /var/lib/neo4j/conf/neo4j.conf

RUN sed -i \
  's/^#dbms\.connector\.http\.advertised_address=:7474$/dbms.connector.http.advertised_address=:8080/' \
  /var/lib/neo4j/conf/neo4j.conf

ARG GITHUB_SHA=missing
ENV GITHUB_SHA=${GITHUB_SHA}

ARG GITHUB_REF=missing
ENV GITHUB_REF=${GITHUB_REF}
