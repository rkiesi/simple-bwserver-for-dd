FROM eclipse-temurin:11

RUN mkdir -p /opt/app

ADD . /opt/app
WORKDIR /opt/app
RUN wget -O dd-java-agent.jar https://dtdg.co/latest-java-tracer

EXPOSE 8500

ENV APP_NAME_ON_DD my-http-app
ENV APP_VERSION_ON_DD 1.0
ENV APP_ENV_ON_DD testing
ENV DD_AGENT_URL http://192.168.49.1:8126

ENTRYPOINT java \
-javaagent:dd-java-agent.jar \
-cp /opt/app/ \
-Ddd.profiling.enabled=true \
-XX:FlightRecorderOptions=stackdepth=256 \
-Ddd.logs.injection=true \
-Ddd.service=${APP_NAME_ON_DD} \
-Ddd.version=${APP_VERSION_ON_DD} \
-Ddd.env=${APP_ENV_ON_DD} \
-Ddd.trace.agent.url=${DD_AGENT_URL} \
com/logicbig/example/BasicHttpServerExample2
