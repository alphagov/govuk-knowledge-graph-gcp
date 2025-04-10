FROM mongo:8.0.4

# Install gcloud
# https://cloud.google.com/sdk/docs/install#deb
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y
RUN apt-get install -y \
  apt-transport-https \
  ca-certificates \
  gnupg \
  curl
RUN \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && apt-get update -y \
  && apt-get install google-cloud-cli -y \
  # Clean up
  && rm -rf /var/lib/apt/lists/*

# TODO Not entirelqy sure if we need this, but it is in the publisher dockerfile
ARG GITHUB_SHA=missing
ENV GITHUB_SHA=${GITHUB_SHA}

ARG GITHUB_REF=missing
ENV GITHUB_REF=${GITHUB_REF}

# TODO - do we need the entrypoint for the retry logic? (publisher dockerfile does not use it)
# Reset the postgres entrypoint to the docker default, so that we can run our
# own CMD
ENTRYPOINT []
COPY entrypoint.sh .
CMD bash entrypoint.sh
