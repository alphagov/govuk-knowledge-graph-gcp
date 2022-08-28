FROM mongo:4.4.16

# Install gsutil and python with BeautifulSoup
# https://cloud.google.com/sdk/docs/install#deb
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y
RUN apt-get install -y \
  apt-transport-https \
  ca-certificates \
  make \
  gnupg \
  curl \
  python3-bs4
RUN \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && apt-get update -y \
  && apt-get install google-cloud-cli -y \
  # Clean up
  && rm -rf /var/lib/apt/lists/*

ARG GITHUB_SHA=missing
ENV GITHUB_SHA=${GITHUB_SHA}

ARG GITHUB_REF=missing
ENV GITHUB_REF=${GITHUB_REF}

# Run a script from a copy of the HEAD of the repository
CMD \
  gsutil cat gs://govuk-knowledge-graph-repository/docker/mongodb/run.sh \
  | bash
