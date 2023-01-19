FROM postgres:13-bullseye

ENV DEBIAN_FRONTEND noninteractive
# Prepare to install things
RUN apt-get update -y
RUN \
# Install gcloud and python with BeautifulSoup
# https://cloud.google.com/sdk/docs/install#deb
  apt-get install -y \
  apt-transport-https \
  ca-certificates \
  make \
  parallel \
  gnupg \
  curl \
  w3m \
  python3-bs4 \
  && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && apt-get update -y \
  && apt-get install google-cloud-cli -y \
  # Install govspeak
  && apt-get install -y \
  gcc \
  ruby-full \
  && gem install govspeak -v 7.0.0 \
  # Clean up
  && apt-get remove -y gcc \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

ARG GITHUB_SHA=missing
ENV GITHUB_SHA=${GITHUB_SHA}

ARG GITHUB_REF=missing
ENV GITHUB_REF=${GITHUB_REF}

# Reset the postgres entrypoint to the docker default, so that we can run our
# own CMD
ENTRYPOINT []

ENV PROJECT_ID=govuk-knowledge-graph-staging

# Run a script from a copy of the HEAD of the repository
CMD \
  gcloud storage cat "gs://${PROJECT_ID}-repository/docker/postgres/run.sh" \
  | bash
