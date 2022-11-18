# How to test for OTLP reporting from BW Engine?

TIBCO BusinessWorks Container Edition comes with built in support for OTLP (Open Telemetry Protocol). The docs claim that the OTLP libs are already included and the application server code is written in a way that is emits proper spans and measures that are specific to the BWCE applications. That could be e.g. for a REST service the arrival of a HTTP request and the returned reply and in between measures for each activity called during the BW integration flow execution.

## Configuration of the BWCE built-in OTLP

What configuration is needed depends on the approach chosen from the Datadog options. Either OTLP forewarding via an already existing DD-Agent is used [OTLP Trace Ingestion by the Datadog Agent](https://docs.datadoghq.com/tracing/trace_collection/open_standards/otlp_ingest_in_the_agent/?tab=docker#enabling-otlp-ingestion-on-the-datadog-agent) or the additional [OpenTelemetry collector Datadog exporter](https://docs.datadoghq.com/tracing/trace_collection/open_standards/otel_collector_datadog_exporter) is used. For more details on the options see the Datadog Blog [Ingest OpenTelemetry traces and metrics with the Datadog Agent](https://www.datadoghq.com/blog/ingest-opentelemetry-traces-metrics-with-datadog-agent/).
If needed, more details on the OTLP exporter configuration can be found at [OpenTelemtry - Collector - Configuration](https://opentelemetry.io/docs/collector/configuration/).

*For our tests we were using the DD-Agent as OTLP metrics forewarder.*


## Testing what is issued via OTLP from a BWCE application

OTLP metric data can be transferred eiter via gRPC or HTTP protocol.

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

## Setup DD-Agent for OLTP

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

Starting an all-in-one Jager server - essentially following [Introducing native support for OpenTelemetry in Jaeger](https://medium.com/jaegertracing/introducing-native-support-for-opentelemetry-in-jaeger-eb661be8183c) as the BWCE engine also got native OLTP support:
```
docker run -d --rm \
  --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

Starting an BWCE application container with **Jaeger all-in-one server** as OLTP target:
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