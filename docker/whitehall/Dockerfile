FROM debian:13.3

# Install the gcloud CLI, a specific version from a long-term archive
# Adapted from https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/master/alpine/Dockerfile
# Also install make, and GNU sed (for Q command) and coreutils (for faster wc)
ENV CLOUD_SDK_VERSION=452.0.1
ENV PATH /google-cloud-sdk/bin:$PATH
RUN groupadd -g 1000 cloudsdk && \
    useradd -u 1000 cloudsdk -g cloudsdk
RUN if [ `uname -m` = 'x86_64' ]; then echo -n "x86_64" > /tmp/arch; else echo -n "arm" > /tmp/arch; fi;
RUN ARCH=`cat /tmp/arch` && apt update && apt install -y \
        coreutils \
        curl \
        python3 \
        python3-crcmod \
        python3-openssl \
        libc6-dev \
        openssh-client \
        gnupg \
        make \
        mariadb-server \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
    tar xzf google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
    rm google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version

RUN mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql && \
    mkdir -p /data/mysql && \
    chown -R mysql:mysql /data/mysql && \
    mkdir /run/mysqld/ && \
    chown mysql:mysql /run/mysqld/ && \
    mariadb-install-db --datadir=/var/lib/mysql

COPY my.cnf /etc/mysql/conf.d/mysql.cnf

# Reset the postgres entrypoint to the docker default, so that we can run our
# own CMD
ENTRYPOINT []
COPY entrypoint.sh .
CMD bash entrypoint.sh
