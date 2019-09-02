FROM ubuntu:19.04
MAINTAINER ted.jung@elastic.co

ENV ES_VERSION 7.3.1
ENV DOWNLOAD_URL "https://artifacts.elastic.co/downloads/elasticsearch"
ENV ES_TARBAL "${DOWNLOAD_URL}/elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz"
ENV ES_TARBALL_ASC "${DOWNLOAD_URL}/elasticsearch-${ES_VERSION}.tar.gz.asc"
ENV GPG_KEY "46095ACC8548582C1A2699A9D27D666CD88E42B4"

RUN groupadd -g 1000 elasticsearch && useradd elasticsearch -u 1000 -g 1000
# Install jdk
RUN apt update && apt install -y openjdk-8-jdk-headless util-linux
# Install Elasticsearch.
RUN apt install -y apt-transport-https ca-certificates curl software-properties-common && \
  cd /tmp && \
  echo "===> Download tar..." && \
  curl -o elasticsearch.tar.gz ${ES_TARBAL} && \
  echo "===> Install Elasticsearch..." && \
  tar -xf elasticsearch.tar.gz && \
  ls -lah && \
  mv elasticsearch-$ES_VERSION elasticsearch && \
  mv elasticsearch /etc && \
  mkdir -p /etc/elasticsearch/config/scripts /etc/elasticsearch/plugins /mnt/data /mnt/log /etc/elasticsearch/config/certs && \
  chown -Rf elasticsearch:elasticsearch /etc/elasticsearch /etc/elasticsearch/config/certs /mnt && \
  chown -Rf elasticsearch:elasticsearch /mnt/data /mnt/log && \
  apt install -y sudo && \
  echo '$sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  ls -al /etc/elasticsearch/certs && \
  rm -rf /tmp/*

WORKDIR /etc/elasticsearch
# Volume for Elasticsearch data
VOLUME ["/mnt/data"]

# Copy configuration & run script
# Certs files in ./config/certs
COPY config /etc/elasticsearch/config
COPY run.sh /etc/elasticsearch
COPY certs /etc/elasticsearch/config/certs
#USER elasticsearch

RUN chown -R elasticsearch:elasticsearch /etc/elasticsearch/config/certs

#USER elasticsearch

ENV PATH /etc/elasticsearch/bin:$PATH
# Set environment variables defaults
# Do not define node name to create multiple node

ENV ES_JAVA_OPTS ${ES_JAVA_OPTS}
ENV CLUSTER_NAME ${CLUSTER_NAME}
ENV NODE_NAME ${NODE_NAME}
ENV NODE_MASTER ${NODE_MASTER}
ENV NODE_DATA ${NODE_DATA}
ENV NODE_INGEST ${NODE_INGEST}
ENV NETWORK_HOST ${NETWORK_HOST}
ENV MEMORY_LOCK ${MEMORY_LOCK}
ENV CLUSTER_INITIAL_MASTER_NODES ${NODE_NAME}
ENV DISCOVERY_SEED_HOSTS ${NODE_NAME}

CMD ["/etc/elasticsearch/run.sh"]

EXPOSE 9200 9300
