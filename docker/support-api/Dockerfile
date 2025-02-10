FROM postgres:16.0-alpine3.18

# Install the gcloud CLI, a specific version from a long-term archive
# Adapted from https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/master/alpine/Dockerfile
# Also install make, and GNU sed (for Q command) and coreutils (for faster wc)
ENV CLOUD_SDK_VERSION=452.0.1
ENV PATH /google-cloud-sdk/bin:$PATH
RUN addgroup -g 1000 -S cloudsdk && \
    adduser -u 1000 -S cloudsdk -G cloudsdk
RUN if [ `uname -m` = 'x86_64' ]; then echo -n "x86_64" > /tmp/arch; else echo -n "arm" > /tmp/arch; fi;
RUN ARCH=`cat /tmp/arch` && apk --no-cache add \
        sed \
        coreutils \
        curl \
        python3 \
        py3-crcmod \
        py3-openssl \
        bash \
        libc6-compat \
        openssh-client \
        gnupg \
        make \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
    tar xzf google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
    rm google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version

# Reset the postgres entrypoint to the docker default, so that we can run our
# own CMD
ENTRYPOINT []
COPY entrypoint.sh .
CMD bash entrypoint.sh
