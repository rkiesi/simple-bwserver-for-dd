FROM tibco/bwce:latest

LABEL maintainer="rkiessli@tibco.com"

ADD SimpleServerDemo_1.0.0.ear /

# REST Endpoint will be exposed at:
EXPOSE 8088

# Datadog instrumenation parameters
#ENV APP_NAME_ON_DD tibco-bw-app
ENV APP_NAME_ON_DD simple-bwserver-demo
ENV APP_VERSION_ON_DD 1.0
ENV APP_ENV_ON_DD testing
ENV DD_AGENT_URL http://192.168.49.1:8126

# set entrypoint for bwce containers
ENTRYPOINT ["/scripts/start.sh"]
