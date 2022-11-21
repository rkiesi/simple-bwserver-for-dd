# How to test for OTLP reporting from BW Engine?

TIBCO BusinessWorks Container Edition comes with built in support for OTLP (Open Telemetry Protocol). The docs claim that the OTLP libs are already included and the application server code is written in a way that is emits proper spans and measures that are specific to the BWCE applications. That could be e.g. for a REST service the arrival of a HTTP request and the returned reply and in between measures for each activity called during the BW integration flow execution.

## Configuration of the BWCE built-in OTLP

What configuration is needed depends on the approach chosen from the Datadog options. Either OTLP forewarding via an already existing DD-Agent is used [OTLP Trace Ingestion by the Datadog Agent](https://docs.datadoghq.com/tracing/trace_collection/open_standards/otlp_ingest_in_the_agent/?tab=docker#enabling-otlp-ingestion-on-the-datadog-agent) or the additional [OpenTelemetry collector Datadog exporter](https://docs.datadoghq.com/tracing/trace_collection/open_standards/otel_collector_datadog_exporter) is used. For more details on the options see the Datadog Blog [Ingest OpenTelemetry traces and metrics with the Datadog Agent](https://www.datadoghq.com/blog/ingest-opentelemetry-traces-metrics-with-datadog-agent/).
If needed, more details on the OTLP exporter configuration can be found at [OpenTelemtry - Collector - Configuration](https://opentelemetry.io/docs/collector/configuration/).

*For our tests we were using the DD-Agent as OTLP metrics forewarder.*


## Testing what is issued via OTLP from a BWCE application

[OTLP](https://opentelemetry.io/docs/reference/specification/protocol/) metric data can be transferred eiter via gRPC or HTTP protocol.

A first test showed that a [Jaeger](https://www.jaegertracing.io/docs/1.6/getting-started/) server will iunderstand metrics issued by a BWCE engine. Details on how to instrument a simple application for OpenTelemtry and setup and test a Jaeger server can be found as a nice article on Medium: [Jaeger Tracing: A Friendly Guide for Beginners](https://medium.com/jaegertracing/jaeger-tracing-a-friendly-guide-for-beginners-7b53a4a568ca).

In order to understand the wire protocol used, I wanted to see the OTLP requests sent from the BW engine to the OTLP service. I was assuming the HTTP transport is used, therfore we might be able to simulate an OTLP collector with a simple HTTP service and log all requests. Here, a simple Python application might help us [Gist](https://gist.github.com/mdonkers/63e115cc0c79b4f6b8b3a6b797e485c7). Idea is to simply point the BWCE engine to the Python HTTP service..


Stating the HTTP logger server: `python3 simpleHttpRequestLogger.py 8082`

Simple test call: `curl -vk --url http://192.168.49.1:8082/otlp --request POST --data '{"data":"sample"}'`

Starting the BWCE application container and pointing to our HTTP logger service
```
docker run --rm -ti \
  -p 8088:8088/tcp \
  -e BW_ENGINE_THREADCOUNT=4 \
  -e BW_LOGLEVEL=WARN \
  -e BW_JAVA_OPTS="-Dbw.engine.opentelemetry.enable=true -Dbw.engine.opentelemetry.span.exporter.endpoint=http://192.168.49.1:4317" \
  -e APP_NAME_ON_DD=simple-bwserver-demo3 \
  -e APP_VERSION_ON_DD=1.1.b \
  -e APP_ENV_ON_DD=pre-prod-test \
  -e DD_AGENT_URL="http://192.168.49.1:8126" \
  --name bwservice-ot \
  simple-bwserver-demo:latest
```

OK, the results logged for the OTLP requests prove our assumption that HTTP transport was used is wrong. Instead the BW engine uses the gRPC protocol via HTTP/s. Log entry `"PRI * HTTP/2.0" 505 - code 505, message Invalid HTTP version (2.0)`.
Now we know for sure **gRPC** must be enabled on DD-Agent!

## Setup DD-Agent for OTLP

Following is a sample on how to start the DD-Agent container to enable OpenTelemtry support on DataDog. To enable OTLP the DD-Agent is expecting variables to set `DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT` and/or `DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_HTTP_ENDPOINT=0.0.0.0:4318`. Both ports must be exposed by the container.

```
docker run -d \
 --name dd-agent \
 --rm \
 -v /var/run/docker.sock:/var/run/docker.sock:ro \
 -v /proc/:/host/proc/:ro \
 -v /opt/datadog-agent/run:/opt/datadog-agent/run:rw \
 -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
 -p 8125:8125/udp \
 -p 8126:8126/tcp \
 -p 4317:4317/tcp \
 -p 4318:4318/tcp \
 -e DD_API_KEY=${DATADOG_API_KEY} \
 -e DD_SITE=${DATADOG_SITE} \
 -e DD_LOGS_ENABLED=true \
 -e DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true \
 -e DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_GRPC_ENDPOINT=0.0.0.0:4317 \
 -e DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_HTTP_ENDPOINT=0.0.0.0:4318 \
 gcr.io/datadoghq/agent:7
```

## Starting BWCE Application with DataDog and OpenTelemtry enabled

Starting the BWCE application container and enable DataDog instrumentation as well as OpenTelemtry data exports.

THe TIBCO BWCE documentation explaines how to enable the built-in OpenTelemtry support by providing JVM parameters `-Dbw.engine.opentelemetry.enable=true -Dbw.engine.opentelemetry.span.exporter.endpoint=http://192.168.49.1:4317`. Those need to be passed as environment variable `BW_JAVA_OPTS` to the BWCE appliaction conatiner to be piced up by the BW engine. - docs:[BWCE 2.8.0 Configuring Opentelemetry](https://docs.tibco.com/pub/bwce/2.8.0/doc/html/Default.htm#app-dev-guide/environment-variable.htm)

There are more BW related environment variables available to control the BW application server behaviour - docs: [BWCE 2.8.0 Environment Variables for Docker](https://docs.tibco.com/pub/bwce/2.8.0/doc/html/Default.htm#app-dev-guide/environment-variable.htm)

The remaining environment variable parameters are the ones expected by the DD-Agent - [Docker Agent for Docker, containerd, and Podman - Environment variables](https://docs.datadoghq.com/containers/docker/?tab=standard#environment-variables).


```
docker run --rm -ti \
  -p 8088:8088/tcp \
  -e BW_ENGINE_THREADCOUNT=4 \
  -e BW_LOGLEVEL=WARN \
  -e BW_JAVA_OPTS="-Dbw.engine.opentelemetry.enable=true -Dbw.engine.opentelemetry.span.exporter.endpoint=http://192.168.49.1:4317" \
  -e APP_NAME_ON_DD=simple-bwserver-demo3 \
  -e APP_VERSION_ON_DD=1.1.b \
  -e APP_ENV_ON_DD=pre-prod-test \
  -e DD_AGENT_URL="http://192.168.49.1:8126" \
  --name bwservice-ot \
  simple-bwserver-demo:latest
```

## What about OLTP with Jaeger?

Starting an all-in-one Jager server - essentially following [Introducing native support for OpenTelemetry in Jaeger](https://medium.com/jaegertracing/introducing-native-support-for-opentelemetry-in-jaeger-eb661be8183c) as the BWCE engine also got native OTLP support:
```
docker run -d --rm \
  --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

Starting an BWCE application container with **Jaeger all-in-one server** as OpenTelemetry target:
```
docker run --rm -ti \
  -p 8088:8088/tcp \
  -e BW_ENGINE_THREADCOUNT=4 \
  -e BW_LOGLEVEL=INFO \
  -e BW_JAVA_OPTS="-Dbw.engine.opentelemetry.enable=true -Dbw.engine.opentelemetry.span.exporter.endpoint=http://192.168.49.1:4317" \
  --name bwservice-ot \
  simple-bwserver-demo:latest
```

Now, open the URL *http://<your-host>:16686* with you browser to follow the metrics and spans sent by our BWCE application.


## Using TIBCO provided BWCE Monitoring Application **BWCEMon**

The above ways to monitor the behaviour of an BWCE application are not able to provide insiht on the business integration application inner workings. The TIBCO provided BWCE monitoring application is better suited to show execatly the needed KPIs for a BusinessWorks application.
For Setup of BWCEMon please follow the documentation for your environment:
* [TIBCO BusinessWorks Container Edition Application Monitoring and Troubleshooting](https://docs.tibco.com/pub/bwce/2.8.0/doc/pdf/TIB_bwce_2.8.0_application_monitoring_troubleshooting.pdf) - Application Monitoring on Docker
* [TIBCO BusinessWorks Container Edition Application Monitoring and Troubleshooting](https://docs.tibco.com/pub/bwce/2.8.0/doc/pdf/TIB_bwce_2.8.0_application_monitoring_troubleshooting.pdf) - Setting Up BWCE Application Monitoring on Kubernetes

A list of measures available for BWCEMon and via OpenTelemtry is available at [OpenTelemetry Tags From Palettes](https://docs.tibco.com/pub/bwce/2.8.0/doc/html/Default.htm#bwce-app-monitoring/opentracing-tags-fro.htm).

### Configuring needed MySQL Database

BWCEMon requires a supported relational database server to be present as the monitoring application will save all collected metrics data for BWCE applications connecting to it. For a local test we are using MySQL as a local server, depolyed side by side with the local docker runtime.

```
$ mysql -u root -p

mysql> CREATE USER 'bwcemon'@'%' IDENTIFIED WITH mysql_native_password BY 'passw0rd';
mysql> CREATE DATABASE IF NOT EXISTS bwcemon CHARACTER SET utf8mb4;

mysql> GRANT ALL PRIVILEGES ON bwcemon.* TO 'bwcemon'@'%' WITH GRANT OPTION;

# Check:
# - reason: node.js mqsldb module is not yet capable of using the newer MySQL authentication method!
# - listed plugin must be mysql_native_password!

mysql> SELECT user,authentication_string,plugin,host FROM mysql.user;
+------------------+------------------------------------------------------------------------+-----------------------+-----------+
| user             | authentication_string                                                  | plugin                | host      |
+------------------+------------------------------------------------------------------------+-----------------------+-----------+
| bwcemon          | *74B1C21ACE0C2D6B0678A5E503D2A60E8F9651A3                              | mysql_native_password | %         |
```

### Running BWCEMon as Container

```
docker run --rm \
 -p 8080:8080 \
 -p 443:443 \
 -e PERSISTENCE_TYPE="mysql" \
 -e DB_URL="mysql://bwcemon:passw0rd@192.168.49.1:3306/bwcemon" \
 -e "BW_APP_MON_REGISTER_ATTEMPTS=5" \
 -e "BW_APP_MON_REGISTER_DELAY=3000" \
 -e HTTPS=true \
 --name bwcemon\
 tibc/bwcemon:2.8.0
```

### Starting a BWCE Application with Monitoring by BWCEMon

Starting an BWCE application container with **BWCEMon supervision**:
```
docker run --rm -ti \
  -p 8088:8088/tcp \
  -e BW_ENGINE_THREADCOUNT=4 \
  -e BW_LOGLEVEL=INFO \
  -e BW_JAVA_OPTS="-Dbw.frwk.event.subscriber.instrumention.enabled=true" \
  -e BW_APP_MONITORING_CONFIG='{"url":"http://192.168.49.1:8080"}' \
  --name bwservice-mon \
  simple-bwserver-demo:latest
```
