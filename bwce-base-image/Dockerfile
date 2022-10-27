FROM debian:bullseye-slim

LABEL maintainer="TIBCO Software Inc."

# copy all TIBCO BWCE runtime artifacts into the image
ADD . /

# patch container start.sh to add Datadog instrumention patch
RUN \
if [ -f "/scripts/dd-patch-bwappnode.sh" ]; then \
  echo "[INFO] adding Datadog Patch for BWCE node startup"; \
  sed '/^exec bash $BWCE_HOME.*/i source \/scripts\/dd-patch-bwappnode.sh' /scripts/start.sh > /scripts/start.sh.dd; \
  mv /scripts/start.sh /scripts/start.sh_original; \
  mv /scripts/start.sh.dd /scripts/start.sh; \
fi

# as superuser: make all TIBCO scripts executable & update OS software packages
RUN \
chmod 755 /scripts/*.sh && \
apt-get update && \
apt-get --no-install-recommends -y install unzip ssh net-tools wget && \
apt-get clean && \
rm -rf /var/lib/apt/lists/*

# add Datadog instrumentation library [Tracing Java Applications](https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/java/?tab=containers)
RUN mkdir -p /resources/instrumentation && \
wget --no-check-certificate -O /resources/instrumentation/dd-java-agent.jar https://dtdg.co/latest-java-tracer

# add an BWCE OS group and user
RUN groupadd -g 2001 bwce && \
useradd -m -d /home/bwce -r -u 2001 -g bwce bwce

# from now on work as user "bwce"
USER bwce

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# set entrypoint for containers
#ENTRYPOINT ["/scripts/start.sh"]
CMD ["/scripts/start.sh"]